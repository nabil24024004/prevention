# Features Documentation

## Overview

Prevention app provides a comprehensive suite of features designed to help users overcome pornography addiction through accountability, motivation, and technical safeguards.

---

## 🔒 1. DNS-Based Content Blocking

### Description
Always-on VPN service that filters web traffic through Cloudflare Family DNS (1.1.1.3) to block explicit content.

### Technical Implementation

**Android VPN Service** (`BlockerVpnService.kt`):
- Uses Android `VpnService` API
- Configures DNS to Cloudflare Family (1.1.1.3 & 1.0.0.3)
- Excludes app itself from VPN tunnel
- Persists VPN state across reboots

**Key Components**:
```kotlin
// DNS Configuration
builder.addDnsServer("1.1.1.3")  // Cloudflare Family primary
builder.addDnsServer("1.0.0.3")  // Cloudflare Family secondary
```

### User Flow

1. User enables blocker from dashboard
2. VPN permission requested (first time)
3. VPN establishes connection
4. All device traffic routes through Cloudflare Family DNS
5. Explicit content automatically blocked
6. VPN persists until manually disabled

### Security Measures

- **Tamper Detection**: Checks for VPN disable attempts
- **External VPN Blocking**: Prevents bypass using third-party VPNs
- **Auto-restart**: Recovers from crashes/kills

---

## 📊 2. Streak Tracking System

### Description
Gamified sobriety tracking that requires daily check-ins to maintain and grow a "days clean" streak.

### Core Mechanics

**Daily Check-In**:
- Required once per 24-hour period
- Captures mood (great/good/okay/struggling)
- Optional notes (max 500 characters)
- Server validates and increments streak

**Streak Calculation**:
- Contiguous days of completed check-ins
- Missed day = streak resets to 0
- Best streak tracked separately

### Technical Architecture

**Client** (`DashboardRepository.dart`):
```dart
Future<void> logDailyCheckIn({required String mood, String? notes}) async {
  // VPN enforcement
  // Rate limiting check
  // Call RPC
  await _client.rpc('log_daily_checkin', params: {...});
}
```

**Server** (`log_daily_checkin` PostgreSQL function):
1. Validates authentication
2. Checks rate limits (5/hour)
3. Validates mood enum
4. Upserts daily_log entry
5. Calls `recalculate_streak()`
6. Updates user's current_streak_days

**Streak Recalculation Algorithm**:
```sql
WITH RECURSIVE streak_calc AS (
  -- Start from latest check-in (today or yesterday)
  SELECT date, 1 AS count FROM daily_log WHERE ...
  UNION ALL
  -- Find consecutive previous days
  SELECT d.date, s.count + 1 FROM daily_log d
  INNER JOIN streak_calc s ON d.date = (s.date - 1)
)
SELECT max(count) -- Current streak
```

### Anti-Tampering

- ✅ All logic server-side (client cannot manipulate)
- ✅ Rate limited to prevent spam
- ✅ VPN enforcement (blocks check-ins if external VPN active)
- ✅ Input validation (mood enum, notes length)
- ✅ **Duplicate Prevention**: Client & server checks prevent multiple check-ins per day
- ✅ **Status Locking**: UI prevents contradictions (can't check-in if relapsed, can't relapse if checked-in)

---

## 🚨 3. Panic Mode with Screen Pinning Lockdown

### Description
Emergency intervention tool designed to break the "trance" of temptation through time-locking, screen pinning, and motivation.

### Key Features

1.  **Mandatory 5-Minute Timer**:
    - Locks user in the screen for 300 seconds
    - Prevents impulsive navigation away from help
    - Disables "I AM CALM NOW" button until timer ends

2.  **Screen Pinning Lockdown (Android)**:
    - Uses Android's native `startLockTask()` API
    - Blocks Home, Recents, and Back buttons
    - User confirms once with "Pin this app?" prompt
    - Exit requires holding Back + Recents together
    - State persists across app restarts

3.  **Visual Motivation**:
    - **Pulsing Warning**: Red gradient visual cue
    - **Streak Display**: Shows current streak to leverage loss aversion ("Don't break your streak of X days")
    - **Future Warning**: "One moment of weakness isn't worth losing this progress"

4.  **Spiritual Grounding**:
    - Random Islamic Duas displayed
    - Prompt to read aloud

### Technical Implementation

| Layer | Component | Purpose |
|-------|-----------|---------|
| **Flutter** | `blocker_repository.dart` | Persists panic end time, calls screen pin |
| **Flutter** | `main.dart` | Checks for active panic on app startup |
| **Flutter** | `router.dart` | Redirects to panic screen if panic is active (priority over auth) |
| **Flutter** | `panic_mode_screen.dart` | 5-min timer, restores on restart |
| **Android** | `MainActivity.kt` | `startLockTask()` / `stopLockTask()` handlers |
| **Android** | `AndroidManifest.xml` | `REORDER_TASKS` permission |

**Screen Pinning Flow**:
```
User taps "PANIC MODE" button
        ↓
setPanicModeActive(300) called
        ↓
1. Save end timestamp to SharedPreferences
2. Call native setPanicLockdown(true)
3. Call startLockTask() → Android prompts "Pin this app?"
        ↓
User taps "Start" on Android dialog
        ↓
App is now pinned - Home/Back/Recents blocked
        ↓
Timer counts down (persists if app killed)
        ↓
Timer hits 0 → clearPanicMode() called
        ↓
1. Stop screen pin via stopLockTask()
2. Clear SharedPreferences
3. Navigate back to dashboard
```

**Persistence Across Restart**:
```dart
// In main.dart
final panicSecondsRemaining = await blockerRepository.getPanicSecondsRemaining();
if (panicSecondsRemaining > 0) {
  // Resume on panic screen with remaining time
}
```

### Limitations

> **Note**: Without Device Owner privileges (requires ADB setup), true Kiosk Mode is not possible. Screen Pinning is the strongest consumer-friendly lockdown available. Users can exit by holding Back + Recents buttons together.

---

## 🕌 4. Islamic Motivation Content

### Description
Curated collection of Quranic verses, Hadith, and Islamic guidance related to purity, chastity, and overcoming temptation.

### Content Categories

1. **Quranic Verses**
   - Surah An-Nur (Light) - verses on modesty
   - Surah Al-Isra - guarding private parts
   - Surah Al-Mu'minun - characteristics of believers

2. **Hadith Collections**
   - Marriage as protection
   - Fasting for unmarried individuals
   - Lowering the gaze
   - Seeking Allah's help

3. **Duas & Supplications**
   - Protection from desires
   - Strength to resist temptation
   - Repentance prayers

### Technical Implementation

**Database** (`content_resources` table):
```sql
{
  id: UUID,
  category: 'quran' | 'hadith' | 'dua' | 'story',
  title: TEXT,
  arabic_text: TEXT,
  english_translation: TEXT,
  reference: TEXT, -- Surah/Hadith reference
  tags: TEXT[]
}
```

**Access Control**:
- Public read for authenticated users (RLS policy)
- Admin-only write access
- Content versioned and reviewed

### User Experience

- Browse by category
- Daily rotation of highlighted content
- Bookmark favorites
- Share with accountability partner

---

## 💔 5. Relapse Accountability Flow

### Description
Structured 3-step process for logging relapses that enforces reflection and prevents casual streak resets.

### Flow Steps

**Step 1: Shame Awareness**
- Display reminder of Islamic teachings
- Visual emphasis on gravity of action
- No skip button (user must acknowledge)

**Step 2: Trigger Selection**
- Stress
- Boredom
- Loneliness
- Curiosity
- Social media
- Custom (type own)

**Step 3: Mandatory Reflection**
- Text field (min 50 chars)
- Questions to guide reflection:
  - What led to this moment?
  - What could I have done differently?
  - What will I do next time?

### Technical Implementation

**Client** (`RelapseFlowScreen.dart`):
- Multi-step wizard UI
- State management via Riverpod
- Form validation before submission

**Server** (`DashboardRepository.logRelapse()`):
```dart
// Insert relapse log
await _client.from('relapses').insert({
  'user_id': userId,
  'trigger': selectedTrigger,
  'reflection': reflectionText,
  'timestamp': DateTime.now()
});

// Reset streak
await _client.from('users').update({
  'start_date': DateTime.now(),
  'last_relapse_date': DateTime.now(),
  'current_streak_days': 0
}).eq('id', userId);
```

### Data Captured

- Timestamp
- Trigger category
- Reflection text
- Previous streak length
- Time since last relapse

### Analytics

Support team can identify:
- Most common triggers
- Relapse patterns (time of day, day of week)
- Average time between relapses
- Effectiveness of interventions

---

## 🔄 6. Offline Sync

### Description
Allows check-ins while offline, syncing automatically when connection restored, with server-side integrity validation.

### How It Works

**Offline Mode**:
1. User attempts check-in without internet
2. Event stored locally in queue
3. UI shows "Pending sync" indicator
4. App attempts sync every 5 minutes

**Sync Process**:
1. Device reconnects to internet
2. App calls `validate_offline_sync()` RPC
3. Server validates each queued event:
   - ✅ Not future-dated (5s tolerance)
   - ✅ No duplicates
   - ✅ Device fingerprint matches
   - ✅ Required fields present
4. Valid events inserted → Streak recalculated
5. Rejected events logged with reasons

### Device Fingerprinting

Each device gets unique ID:
```dart
String deviceId = await DeviceFingerprint.get();
// Example: "android_pixel6_<uuid>"
```

Tracked in `device_fingerprints` table:
- First seen timestamp
- Last seen timestamp
- Device metadata (model, OS version)
- Blocked status

### Conflict Resolution

| Scenario | Resolution |
|----------|-----------|
| Duplicate date | Server wins, offline rejected |
| Future timestamp | Rejected |
| Out of order | Accepted with warning |
| Blocked device | All events rejected |

See [conflict_resolution_policy.md](conflict_resolution_policy.md) for full details.

---

## 🛡️ 7. Security Features

### VPN Enforcement

**External VPN Detection**:
- Checks `NetworkCapabilities.TRANSPORT_VPN`
- Distinguishes app's VPN from external VPNs
- Blocks check-ins if external VPN active

**Bypass Prevention**:
```dart
if (await blockerRepo.isExternalVpnActive()) {
  throw Exception('External VPN detected. Disable to check in.');
}
```

### Anti-Tampering

**Emulator Detection**:
- Build fingerprints (`generic`, `google_sdk`)
- Hardware checks (`goldfish`, `ranchu`)
- Known emulator files (`/dev/qemu_pipe`)

**Root Detection**:
- Test-keys in Build.TAGS
- Su binary paths (10 common locations)
- Command execution tests

### Rate Limiting

**Limits**:
- Check-ins: 5 per hour
- Offline sync: 3 per 30 minutes

**Enforcement**:
```sql
IF NOT check_rate_limit('checkin', 5, 60) THEN
  RAISE EXCEPTION 'Rate limit exceeded';
END IF;
```

### Audit Logging

All security events logged:
- `vpn_detected_during_checkin`
- `tamper_detected`
- `rate_limit_exceeded`
- `offline_sync_rejected`

---

## 📱 8. User Interface

### Dashboard

**Components**:
- Streak counter (animated)
- Live timer (hours/minutes since start)
- Daily check-in button
- VPN toggle
- Islamic content carousel

**Real-time Updates**:
- Listens to Supabase realtime DB
- Streak updates instantly across devices

### Settings

- Account management
- VPN preferences
- Notification settings
- Data export (GDPR compliance)

---

## 🔔 9. Notifications (Planned)

### Daily Reminders
- Check-in reminder at user-set time
- Missed day alert
- Milestone celebrations (7, 30, 90 days)

### Motivational Push
- Random Quranic verse
- Hadith of the day
- Community encouragement

---

**Version**: 2.6.0 beta release  
**Last Updated**: February 9, 2026
