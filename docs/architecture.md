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
- `just_audio` & `audio_session` - Audio playback & session management
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

**Reactive Repositories**:
For features requiring high-frequency UI updates (like audio playback), repositories may extend `ChangeNotifier` to maintain internal state (e.g., `isLoading`, `playingAyahUrl`, `errorMessage`) which can be watched by Riverpod providers and listened to by UI components.

**Benefits**:
- Abstracts data source (easy to swap)
- Testable (can mock)
- Single responsibility
- Reactive UI without complex controller boilerplate


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
- `content_resources` - Islamic content (General)
- `quran_bookmarks` - User-saved Ayahs
- `spiritual_logs` - Prayer, Dhikr, and Quran logs
- `adhkar_content` - Specific supplication content
- `challenges` - Community challenge definitions
- `challenge_participants` - User progress in challenges
- `user_badges` - Earned rewards
- `security_events` - Audit trail
- `rate_limits` - Abuse prevention

---

## Future Architecture Enhancements

### Planned

1. **iOS Support**: Extend to iPhone/iPad using Flutter's multi-platform capabilities.
2. **Web Dashboard**: Admin and user dashboard built with Next.js or Flutter Web.
3. **Analytics Pipeline**: Export anonymized data to BigQuery for recovery pattern analysis.
4. **Push Notifications**: Integrate FCM for check-in reminders and challenge alerts.
5. **AI Trigger Analysis**: ML-based relapse prediction based on check-in patterns.

---

**Version**: 5.1.0 (Documentation Update)  
**Last Updated**: February 9, 2026

