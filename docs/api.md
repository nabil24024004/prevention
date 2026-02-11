# API Documentation

## Overview

Prevention app uses Supabase as the backend, which provides:
- **PostgreSQL Database** with Row Level Security (RLS)
- **Supabase Auth** for user management
- **Remote Procedure Calls (RPCs)** for server-side logic
- **Realtime** subscriptions via WebSockets

---

## Base URL

```
https://YOUR_PROJECT_ID.supabase.co
```

---

## Authentication

### Auth Flow

All API calls require authentication via JWT tokens.

**Headers**:
```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
apikey: <SUPABASE_ANON_KEY>
```

### Sign Up

**Endpoint**: `POST /auth/v1/signup`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response**:
```json
{
  "access_token": "jwt_token_here",
  "refresh_token": "refresh_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  }
}
```

### Sign In

**Endpoint**: `POST /auth/v1/token?grant_type=password`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response**: Same as Sign Up

### Refresh Token

**Endpoint**: `POST /auth/v1/token?grant_type=refresh_token`

**Request**:
```json
{
  "refresh_token": "existing_refresh_token"
}
```

**Response**: New access_token and refresh_token

---

## Database Tables

### users

**Schema**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT,
  username TEXT,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  current_streak_days INT DEFAULT 0,
  best_streak_days INT DEFAULT 0,
  last_relapse_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS Policy**:
- Users can read/update only their own row

**Example Query**:
```dart
final user = await supabase
  .from('users')
  .select()
  .eq('id', userId)
  .single();
```

### daily_log

**Schema**:
```sql
CREATE TABLE daily_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  date DATE NOT NULL,
  mood TEXT CHECK (mood IN ('great', 'good', 'okay', 'struggling')),
  notes TEXT,
  completed_checkin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);
```

**RLS Policy**:
- Users can read/insert/update only their own logs

### relapses

**Schema**:
```sql
CREATE TABLE relapses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  trigger TEXT,
  reflection TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS Policy**:
- Users can read/insert only their own relapses
- No updates/deletes (immutable)

### content_resources

**Schema**:
```sql
CREATE TABLE content_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT, -- 'quran', 'hadith', 'dua'
  title TEXT,
  arabic_text TEXT,
  english_translation TEXT,
  reference TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS Policy**:
- All authenticated users can read
- Only admins can write

### quran_bookmarks

**Schema**:
```sql
CREATE TABLE quran_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  surah_number INT NOT NULL,
  ayah_number INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, surah_number, ayah_number)
);
```

**RLS Policy**:
- Users can read/insert/delete only their own bookmarks.

### spiritual_logs

**Schema**:
```sql
CREATE TABLE spiritual_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  activity_type TEXT NOT NULL, -- 'prayer', 'dhikr', 'quran_reading'
  sub_type TEXT, -- e.g., 'fajr', 'morning_adhkar'
  value INT DEFAULT 0, -- e.g., dhikr count or reading duration
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS Policy**:
- Users can read/insert/update only their own spiritual logs.

### adhkar_content

**Schema**:
```sql
CREATE TABLE adhkar_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  arabic TEXT NOT NULL,
  translation TEXT,
  transliteration TEXT,
  reference TEXT,
  benefit TEXT,
  target_count INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS Policy**:
- Read access for all authenticated users.

### challenges

**Schema**:
```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL, -- 'streak', 'dhikr', 'quran'
  target_value INT NOT NULL,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  reward_badge_id UUID REFERENCES user_badges(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### challenge_participants

**Schema**:
```sql
CREATE TABLE challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id),
  user_id UUID REFERENCES auth.users(id),
  current_progress INT DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);
```

### user_badges

**Schema**:
```sql
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  category TEXT, -- 'streak', 'spiritual', 'challenge'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```


---

## RPC Functions

### log_daily_checkin

**Purpose**: Securely logs a daily check-in and updates streak

**Signature**:
```sql
log_daily_checkin(p_mood TEXT, p_notes TEXT) RETURNS void
```

**Parameters**:
- `p_mood`: Mood value (`great`, `good`, `okay`, `struggling`)
- `p_notes`: Optional notes (max 500 chars)

**Dart Example**:
```dart
await supabase.rpc('log_daily_checkin', params: {
  'p_mood': 'good',
  'p_notes': 'Feeling strong today'
});
```

**Validations**:
- ✅ Authenticated user
- ✅ Rate limit (5/hour)
- ✅ Mood enum
- ✅ Notes length ≤ 500

**Side Effects**:
- Upserts entry in `daily_log`
- Calls `recalculate_streak()`
- Updates `users.current_streak_days`

---

### recalculate_streak

**Purpose**: Idempotently recalculates user's streak

**Signature**:
```sql
recalculate_streak() RETURNS void
```

**Dart Example**:
```dart
await supabase.rpc('recalculate_streak');
```

**Algorithm**:
1. Find latest check-in (today or yesterday)
2. Recursively count backwards for contiguous days
3. Update `current_streak_days` and `best_streak_days`

---

### validate_offline_sync

**Purpose**: Validates and syncs offline check-in events

**Signature**:
```sql
validate_offline_sync(
  p_events JSONB,
  p_device_id TEXT,
  p_device_info JSONB
) RETURNS TABLE(
  valid BOOLEAN,
  accepted_count INT,
  rejected_count INT,
  rejection_reasons JSONB
)
```

**Parameters**:
- `p_events`: Array of check-in events
- `p_device_id`: Unique device identifier
- `p_device_info`: Device metadata

**Dart Example**:
```dart
final result = await supabase.rpc('validate_offline_sync', params: {
  'p_events': jsonEncode([
    {
      'date': '2025-01-05',
      'timestamp': '2025-01-05T10:30:00Z',
      'mood': 'good',
      'notes': 'Offline check-in'
    }
  ]),
  'p_device_id': deviceId,
  'p_device_info': jsonEncode({
    'model': 'Pixel 6',
    'os_version': 'Android 13'
  })
});

print('Accepted: ${result['accepted_count']}');
print('Rejected: ${result['rejected_count']}');
```

**Validations**:
- ✅ Not future-dated (5s tolerance)
- ✅ No duplicates
- ✅ Device not blocked
- ✅ Required fields present
- ✅ Valid mood value

---

### check_rate_limit

**Purpose**: Checks if user is under rate limit for action

**Signature**:
```sql
check_rate_limit(
  p_action_type TEXT,
  p_max_attempts INT,
  p_window_minutes INT
) RETURNS BOOLEAN
```

**Parameters**:
- `p_action_type`: Action identifier (`checkin`, `sync_offline`)
- `p_max_attempts`: Max allowed attempts
- `p_window_minutes`: Time window

**Returns**: `TRUE` if under limit, `FALSE` if exceeded

**Usage**: Called internally by other RPCs, not directly

---

### log_security_event

**Purpose**: Logs a security event to audit trail

**Signature**:
```sql
log_security_event(
  p_event_type TEXT,
  p_event_data JSONB DEFAULT '{}'::JSONB
) RETURNS void
```

**Dart Example**:
```dart
await supabase.rpc('log_security_event', params: {
  'p_event_type': 'vpn_detected_during_checkin',
  'p_event_data': jsonEncode({'vpn_type': 'external'})
});
```

**Common Event Types**:
- `vpn_detected_during_checkin`
- `tamper_detected`
- `rate_limit_exceeded`
- `offline_sync_rejected`

---

## REST Endpoints (Direct Table Access)

### Get User Profile

**Request**:
```http
GET /rest/v1/users?id=eq.{userId}&select=*
```

**Dart**:
```dart
final user = await supabase
  .from('users')
  .select()
  .eq('id', userId)
  .single();
```

### Get Weekly Check-ins

**Request**:
```http
GET /rest/v1/daily_log?user_id=eq.{userId}&date=gte.2025-01-01&date=lte.2025-01-07&select=*
```

**Dart**:
```dart
final logs = await supabase
  .from('daily_log')
  .select()
  .eq('user_id', userId)
  .gte('date', '2025-01-01')
  .lte('date', '2025-01-07');
```

### Get Islamic Content

**Request**:
```http
GET /rest/v1/content_resources?category=eq.quran&select=*
```

**Dart**:
```dart
final content = await supabase
  .from('content_resources')
  .select()
  .eq('category', 'quran');
```

---

## Realtime Subscriptions

### Listen to User Profile Changes

**Dart**:
```dart
final subscription = supabase
  .from('users')
  .stream(primaryKey: ['id'])
  .eq('id', userId)
  .listen((data) {
    print('User updated: $data');
  });

// Clean up
await subscription.cancel();
```

**Use Case**: Live streak updates across devices

---

## Error Codes

| Code | Message | Cause |
|------|---------|-------|
| `401` | Not authenticated | Missing/invalid JWT |
| `403` | Forbidden | RLS policy violation |
| `429` | Rate limit exceeded | Too many requests |
| `PGRST116` | Not found | Invalid UUID/row |
| `22P02` | Invalid text representation | Type mismatch |
| `42501` | Insufficient privilege | Permission denied |

---

## Rate Limits

| Action | Limit | Window |
|--------|-------|--------|
| Check-in | 5 attempts | 60 minutes |
| Offline sync | 3 attempts | 30 minutes |
| General API | 100 requests | 60 seconds |

---

## Code Examples

### Complete Check-In Flow

```dart
class DashboardRepository {
  final SupabaseClient _client;

  Future<void> performDailyCheckIn(String mood, String? notes) async {
    // 1. Check for external VPN
    final blockerRepo = BlockerRepository();
    if (await blockerRepo.isExternalVpnActive()) {
      throw Exception('External VPN detected');
    }

    // 2. Log check-in via RPC
    await _client.rpc('log_daily_checkin', params: {
      'p_mood': mood,
      'p_notes': notes,
    });

    // 3. Log security event (optional)
    await _client.rpc('log_security_event', params: {
      'p_event_type': 'daily_checkin_success',
      'p_event_data': jsonEncode({'mood': mood})
    });
  }
}
```

### Log Relapse

```dart
Future<void> logRelapse(String trigger, String reflection) async {
  // Insert relapse
  await _client.from('relapses').insert({
    'user_id': userId,
    'trigger': trigger,
    'reflection': reflection,
    'timestamp': DateTime.now().toIso8601String(),
  });

  // Reset streak
  await _client.from('users').update({
    'start_date': DateTime.now().toIso8601String(),
    'last_relapse_date': DateTime.now().toIso8601String(),
    'current_streak_days': 0,
  }).eq('id', userId);
}
```

---

---

## External APIs

### AlQuran Cloud (`api.alquran.cloud`)

**Purpose**: Primary source for Quranic text and audio metadata.

**Key Endpoints**:
- `GET /v1/surah`: Fetch list of all Surahs.
- `GET /v1/surah/{number}/editions/quran-uthmani,en.sahih`: Fetch specific Surah with Arabic text and English translation.
- `GET /v1/surah/{number}/ar.alafasy`: Fetch audio metadata (URLs) for a Surah.

**Security**:
- No API key required for public endpoints.
- App enforces HTTPS for all received audio URLs.

---

**Version**: 5.1.0 (Documentation Update)  
**Last Updated**: February 9, 2026

