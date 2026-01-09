# 🛡️ Prevention - Islamic Accountability App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A comprehensive Islamic mobile app for fighting pornography addiction through accountability, motivation, and DNS-based content blocking.  
> **Current Version**: 2.5.0 beta release (January 9, 2026)

---

## 📱 Overview

**Prevention** is a privacy-first, security-hardened Android application designed to help Muslims overcome pornography addiction through:

- **DNS-based VPN blocking** of explicit content
- **Streak tracking** with mandatory daily check-ins
- **Islamic motivational content** from Quran and Hadith
- **Relapse accountability** with trigger analysis and reflection
- **Enterprise-grade security** to prevent circumvention

---

## ✨ Key Features

### 🔒 Content Blocking
- VPN-based DNS filtering using **Cloudflare Family DNS** (1.1.1.3)
- Always-on protection with automatic restart
- Bypass prevention with external VPN detection
- Tamper-resistant design

### 📊 Accountability System
- **Streak Tracking**: Daily check-ins to maintain sobriety streak
- **Server-side validation**: All streak logic runs in Supabase (tamper-proof)
- **Relapse Flow**: Mandatory 3-step process (shame reminder, trigger selection, reflection)
- **Historical logs**: Complete audit trail of check-ins and relapses

### 🕌 Islamic Motivation
- Curated Quranic verses about purity and taqwa
- Hadith collections on guarding chastity
- Daily reminders and duas
- Community stories of recovery

### 🛡️ Enterprise Security
- **Row Level Security (RLS)** on all database tables
- **Rate limiting** (5 check-ins/hour, 3 syncs/30min)
- **Anti-tampering**: Emulator, root, and debug detection
- **VPN enforcement**: Blocks check-ins if external VPN active
- **Offline integrity**: Device fingerprinting + timestamp validation
- **Audit logging**: Immutable security events table

---

## 🏗️ Architecture

### Tech Stack

**Frontend**:
- **Flutter 3.x** - Cross-platform UI framework
- **Riverpod** - State management
- **Go Router** - Navigation

**Backend**:
- **Supabase** - PostgreSQL database + Auth + Real-time
- **PostgreSQL Functions** - Server-side business logic (streak calculation, validation)

**Native Layer** (Android):
- **Kotlin** - VPN service, tamper detection, network utilities
- **VpnService API** - DNS-based content filtering

### Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Dashboard  │  Islamic Corner  │  Relapse Flow  │   │
│  └─────────────────────────────────────────────────┘   │
│                          │                              │
│  ┌──────────────────────▼──────────────────────────┐   │
│  │         DashboardRepository (Dart)              │   │
│  │  • VPN Enforcement                              │   │
│  │  • Security Logging                             │   │
│  └──────────────────────┬──────────────────────────┘   │
└─────────────────────────┼──────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
┌────────────────┐ ┌──────────────┐ ┌─────────────────┐
│  Native (VPN)  │ │  Supabase    │ │  Native         │
│  • BlockerVPN  │ │  • RLS       │ │  • TamperCheck  │
│  • NetworkUtil │ │  • RPCs      │ │  • Root Detect  │
└────────────────┘ │  • Rate Limit│ └─────────────────┘
                   └──────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android Studio / VS Code
- Android device (API 21+)
- Supabase account

### Installation

1. **Clone repository**:
```bash
git clone https://github.com/yourusername/prevention.git
cd prevention
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Configure Supabase**:
   - Create project at [supabase.com](https://supabase.com)
   - Apply SQL migrations (in order):
     ```
     1. complete_security_migration.sql
     2. security_logging.sql
     3. rate_limiting.sql
     4. input_validation.sql
     ```
   - Update `lib/core/config.dart` with your Supabase URL and anon key

4. **Run app**:
```bash
flutter run
```

---

## 📦 Deployment

### Production Build

```bash
# Clean build
flutter clean
flutter pub get

# Release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Distribution Options

1. **Google Play Internal Testing** (Recommended)
2. **Firebase App Distribution**
3. **Direct APK sharing**

See [deployment_guide.md](docs/deployment_guide.md) for detailed instructions.

---

## 🔐 Security Features

### Implemented Protections

| Feature | Status | Description |
|---------|--------|-------------|
| **RLS Policies** | ✅ | All tables secured with `auth.uid()` scoping |
| **VPN Enforcement** | ✅ | Blocks external VPNs during check-ins |
| **Rate Limiting** | ✅ | 5 check-ins/hour, 3 syncs/30min |
| **Input Validation** | ✅ | Mood enums, length checks, field validation |
| **Offline Integrity** | ✅ | Device fingerprinting + timestamp validation |
| **Anti-Tampering** | ✅ | Emulator, root, debug detection |
| **Security Logging** | ✅ | Immutable audit trail in `security_events` |
| **Server-side Logic** | ✅ | All streak calculations in PostgreSQL |

### Threat Model

Prevents:
- ✅ Client-side streak manipulation
- ✅ Offline data tampering
- ✅ VPN bypassing of blocker
- ✅ Rate limit abuse
- ✅ Emulator/rooted device usage
- ✅ Future-dated check-ins

---

## 📊 Project Structure

```
prevention/
├── android/
│   └── app/src/main/kotlin/
│       └── com/prevention/prevention/
│           ├── BlockerVpnService.kt    # VPN implementation
│           ├── TamperDetector.kt       # Security checks
│           ├── NetworkUtils.kt         # VPN detection
│           └── MainActivity.kt         # Platform channels
├── lib/
│   ├── core/                           # Config, themes, utils
│   ├── features/
│   │   ├── auth/                       # Login, signup
│   │   ├── dashboard/                  # Main screen, check-ins
│   │   ├── blocking/                   # VPN control
│   │   └── islamic_corner/             # Motivational content
│   └── main.dart
└── supabase/migrations/                # SQL files
```

---

## 🧪 Testing

### Local Testing
```bash
# Run unit tests
flutter test

# Run on device
flutter run
```

### Beta Testing
See [testing_instructions.md](docs/testing_instructions.md) for 1-week testing protocol.

---

## 📖 Documentation

- [Deployment Guide](docs/deployment_guide.md) - Production deployment steps
- [Testing Instructions](docs/testing_instructions.md) - Beta testing protocol
- [Session Security](docs/session_security_verification.md) - Supabase auth configuration
- [Conflict Resolution](docs/conflict_resolution_policy.md) - Offline sync policy
- [Security Walkthrough](docs/walkthrough.md) - Complete security implementation

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Flutter style guide
- Add tests for new features
- Update documentation
- Ensure security best practices

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

## 🙏 Acknowledgments

- **Cloudflare Family DNS** for content filtering
- **Supabase** for backend infrastructure
- **Flutter** community for amazing packages

---

## 📞 Support

- **Issues**: [GitHub Issues](https://abrarnabil.vercel.app/)
- **Email**: azwadabrar109@gmail.com
- **Dev Info**: [Azwad Abrar](https://abrarnabil.vercel.app/)

---

**Built with ❤️ to help the Muslim community stay pure in the digital age**
