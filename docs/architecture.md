# Architecture Documentation

## System Overview

Prevention is a 3-tier mobile application with emphasis on security, offline capability, and server-side validation.

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Flutter Application                      │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │ │
│  │  │ Presentation │  │   Business   │  │      Data       │  │ │
│  │  │   (Screens)  │→ │    Logic     │→ │  (Repositories) │  │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────┘  │ │
│  └────────────────────────────────────────┬───────────────────┘ │
│                                           │                     │
│  ┌────────────────────────────────────────▼───────────────────┐ │
│  │              Native Android Layer (Kotlin)                 │ │
│  │  • BlockerVpnService   • TamperDetector                    │ │
│  │  • NetworkUtils        • MainActivity (Platform Channels)  │ │
│  └────────────────────────────────────────┬───────────────────┘ │
└─────────────────────────────────────────┬─┴─────────────────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    ▼                     ▼                     ▼
         ┌──────────────────┐  ┌────────────────┐  ┌──────────────────┐
         │   Supabase Auth  │  │  PostgreSQL DB │  │  Supabase        │
         │  • JWT tokens    │  │  • RLS enabled │  │  Realtime        │
         │  • Refresh logic │  │  • Functions   │  │  (WebSockets)    │
         └──────────────────┘  └────────────────┘  └──────────────────┘
```

---

## Tech Stack Rationale

### Frontend: Flutter

**Why Flutter?**
- ✅ Single codebase for Android (iOS future)
- ✅ Fast development with hot reload
- ✅ Rich UI libraries (Material Design)
- ✅ Strong community and ecosystem
- ✅ Native performance via Dart VM

**Key Packages**:
- `riverpod` - State management (type-safe, testable)
- `go_router` - Declarative routing
- `supabase_flutter` - Backend SDK
- `google_fonts` - Custom typography

### Backend: Supabase

**Why Supabase?**
- ✅ PostgreSQL (ACID, powerful queries)
- ✅ Built-in auth (JWT, refresh tokens)
- ✅ Row Level Security (RLS)
- ✅ Realtime subscriptions
- ✅ Serverless functions (PostgreSQL RPCs)
- ✅ Free tier sufficient for MVP

**Alternatives Considered**:
- Firebase: Rejected (NoSQL limitations, vendor lock-in)
- Custom backend: Rejected (time/complexity)

### Native: Kotlin

**Why Kotlin for Android-specific code?**
- ✅ VpnService API only available natively
- ✅ Better security (tamper detection)
- ✅ Full Android system access

---

## Layer Responsibilities

### 1. Presentation Layer

**Purpose**: UI rendering and user interaction

**Structure**:
```
lib/features/<feature>/presentation/
  ├── <feature>_screen.dart       # Screen widget
  ├── widgets/                    # Reusable components
  └── providers/                  # Riverpod state
```

**Example** (`dashboard_screen.dart`):
- Displays streak counter
- Handles check-in button press
- Shows VPN status
- Listens to user profile stream (realtime)

**Rules**:
- No business logic
- No direct database access
- Calls repositories for data
- UI reacts to state changes

### 2. Business Logic Layer

**Purpose**: Application rules and validation

**Implemented via**:
- Riverpod providers
- Repository pattern

**Responsibilities**:
- Input validation (client-side)
- Error handling
- State management
- Orchestration between data sources

### 3. Data Layer

**Purpose**: Data access and persistence

**Structure**:
```
lib/features/<feature>/data/
  ├── <feature>_repository.dart   # Data operations
  ├── models/                     # Data models
  └── providers/                  # Repository providers
```

**Repository Pattern**:
```dart
class DashboardRepository {
  final SupabaseClient _client;
  
  Future<void> logDailyCheckIn(...) async {
    // VPN check
    // Call Supabase RPC
    // Handle errors
  }
}
```

**Benefits**:
- Abstracts data source (easy to swap)
- Testable (can mock)
- Single responsibility

### 4. Native Layer (Android)

**Purpose**: Platform-specific functionality

**Components**:

**VPN Service**:
```kotlin
class BlockerVpnService : VpnService() {
  override fun onStartCommand(...) {
    // Configure DNS
    // Establish tunnel
    // Persist state
  }
}
```

**Platform Channels**:
```kotlin
// MainActivity.kt
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "blocker")
  .setMethodCallHandler { call, result ->
    when (call.method) {
      "startVpn" -> startVpnService()
      "isRooted" -> result.success(TamperDetector.isRooted())
      "startScreenPin" -> startLockTask() // Screen pinning for Panic Mode
      "stopScreenPin" -> stopLockTask()
    }
  }
```

### 5. Database Layer (Supabase)

**Purpose**: Data persistence and business logic enforcement

**Tables**:
- `users` - User profiles, streak data
- `daily_log` - Check-in history
- `relapses` - Relapse log
- `content_resources` - Islamic content
- `security_events` - Audit trail
- `rate_limits` - Abuse prevention

**PostgreSQL Functions (RPCs)**:
- `log_daily_checkin(mood, notes)` - Validates and logs check-in
- `recalculate_streak()` - Computes current streak
- `validate_offline_sync(events, device_id)` - Validates offline queue
- `check_rate_limit(action, max, window)` - Enforces limits
- `log_security_event(type, data)` - Audit logging

**Why server-side logic?**
- ✅ Tamper-proof (client can't cheat)
- ✅ Centralized validation
- ✅ Consistent across clients
- ✅ Easier to update (no app deploy)

---

## Data Flow

### Check-In Flow

```
User taps "Check In" button
       ↓
DashboardScreen (UI)
       ↓
DashboardRepository.logDailyCheckIn()
       ↓
1. Check external VPN (native call)
   ├─ If detected → Throw error → UI shows message
   └─ If clear → Continue
       ↓
2. Call Supabase RPC: log_daily_checkin(mood, notes)
       ↓
PostgreSQL Function:
  1. Validate auth (auth.uid())
  2. Check rate limit (5/hour)
  3. Validate mood enum
  4. Validate notes length
  5. Upsert daily_log
  6. Call recalculate_streak()
  7. Update users.current_streak_days
       ↓
3. Log security event (if needed)
       ↓
Supabase Realtime fires update
       ↓
UserRepository stream emits new data
       ↓
UI rebuilds with updated streak
```

### Offline Sync Flow

```
User checks in while offline
       ↓
Event queued locally (SharedPreferences/SQLite)
       ↓
App detects connection restored
       ↓
DashboardRepository.syncOfflineEvents()
       ↓
Calls: validate_offline_sync(events_array, device_id)
       ↓
PostgreSQL Function (server-side):
  For each event:
    1. Check duplicate date → Reject if exists
    2. Check future timestamp → Reject if >5s ahead
    3. Validate device fingerprint → Reject if blocked
    4. Validate required fields
    5. Insert valid events
    6. Log rejections
  Finally: recalculate_streak()
       ↓
Returns: {accepted: 3, rejected: 1, reasons: [...]}
       ↓
UI shows sync summary
```

---

## Security Architecture

### Defense in Depth

**Layer 1: Client Validation**
- Input sanitization
- UI constraints (mood dropdown)
- Immediate feedback

**Layer 2: Transport Security**
- HTTPS only
- Certificate pinning (future)
- JWT tokens for auth

**Layer 3: Server Validation**
- All inputs re-validated
- Rate limiting enforced
- RLS policies applied

**Layer 4: Database Security**
- Row Level Security (RLS)
- Encrypted at rest
- Audit logging

### Authentication Flow

```
User signs up/logs in
       ↓
Supabase Auth
  ├─ Creates user in auth.users
  ├─ Generates JWT (1 hour expiry)
  └─ Generates refresh token (30 days)
       ↓
Flutter stores tokens securely
       ↓
Every API call includes JWT in Authorization header
       ↓
Supabase validates JWT
  ├─ Valid → Set auth.uid() context → Execute RPC
  └─ Expired → Client uses refresh token → Get new JWT
       ↓
Refresh token rotation on each refresh (prevents reuse)
```

### RLS Policy Example

```sql
CREATE POLICY "Users can read own daily logs"
  ON daily_log FOR SELECT
  USING (auth.uid() = user_id);
```

**Effect**: Even if client bypasses Dart code and calls DB directly, PostgreSQL enforces user can only see own data.

---

## Scalability Considerations

### Current Architecture (MVP)

**Supports**:
- ~10,000 daily active users
- ~100,000 check-ins per day
- Realtime updates via WebSockets

**Bottlenecks**:
- PostgreSQL connection pooling
- Supabase free tier limits

### Future Scaling

**Horizontal Scaling**:
- Supabase auto-scales read replicas
- Add caching layer (Redis) for hot data

**Optimizations**:
- CDN for static content (images, Islamic texts)
- Database indexing on query-heavy tables
- Background jobs for non-critical tasks

---

## Testing Strategy

### Unit Tests
- Repository logic
- Business rules
- Model serialization

### Integration Tests
- API calls to Supabase
- Native platform channels

### End-to-End Tests
- Full user flows (signup → check-in → relapse)
- Uses test Supabase project

---

## Deployment Architecture

```
Developer
    ↓
GitHub Repository
    ↓
CI/CD (GitHub Actions - future)
    ├─ Run tests
    ├─ Build APK
    └─ Upload to distribution
         ↓
Distribution Channels:
  ├─ Google Play Internal Testing
  ├─ Firebase App Distribution
  └─ Direct APK download
         ↓
End Users (Android devices)
```

---

## Future Architecture Enhancements

### Planned

1. **iOS Support**: Extend to iPhone/iPad
2. **Web Dashboard**: Admin panel for support
3. **Analytics Pipeline**: BigQuery for insights
4. **Push Notifications**: Firebase Cloud Messaging
5. **AI Trigger Analysis**: ML model to predict relapses

### Under Consideration

- Peer accountability (add accountability partners)
- Group challenges (community streaks)
- Therapist integration (share progress with counselor)

---

**Version**: 2.6.0 beta release  
**Last Updated**: February 9, 2026
