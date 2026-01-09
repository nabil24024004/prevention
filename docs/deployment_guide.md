# Production Deployment Guide - 1 Week Testing

## 🎯 Deployment Overview

**Duration**: 1 week testing period  
**Type**: Internal testing / Beta release  
**Platform**: Android APK

---

## 📋 Pre-Deployment Checklist

### 1. Supabase Migrations ⚠️ CRITICAL

**Apply in this exact order** in Supabase SQL Editor:

```
1. complete_security_migration.sql
2. security_logging.sql  
3. rate_limiting.sql
4. input_validation.sql
```

**Verification**:
```sql
-- Check all functions exist
SELECT proname FROM pg_proc WHERE proname IN (
  'log_daily_checkin', 'recalculate_streak', 'validate_offline_sync',
  'log_security_event', 'check_rate_limit'
);
-- Should return 5 rows

-- Check RLS enabled
SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = TRUE;
-- Should return at least 5
```

### 2. Supabase Auth Settings

Follow [session_security_verification.md](file:///C:/Users/capta/.gemini/antigravity/brain/efec1b81-bebf-4e62-971e-b04d8ded3b2b/session_security_verification.md):

- ✅ JWT expiry: 3600 seconds (1 hour)
- ✅ Refresh token rotation: Enabled
- ✅ Reuse detection: Enabled

### 3. Environment Variables

Verify `.env` or hardcoded values:
```dart
// In lib/core/supabase/supabase_config.dart or similar
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_ANON_KEY';
```

---

## 🔨 Build Release APK

### Option A: Release Build (Recommended)

```bash
cd c:\Users\capta\OneDrive\Desktop\Prevention

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

**Output**: `build\app\outputs\flutter-apk\app-release.apk`

### Option B: Split APKs by Architecture (Smaller file size)

```bash
flutter build apk --release --split-per-abi
```

**Output**:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM - most devices)
- `app-x86_64-release.apk` (x86 - emulators)

---

## 📤 Distribution Options

### Option 1: Google Play Internal Testing (Recommended)

**Pros**: Official, auto-updates, easy tester management  
**Steps**:
1. Go to [Google Play Console](https://play.google.com/console)
2. Create app if not exists
3. Go to **Testing → Internal testing**
4. Upload `app-release.apk`
5. Add testers by email
6. Share testing link

**Timeline**: ~2 hours for first review, instant after

### Option 2: Firebase App Distribution

**Pros**: Fast, no review, detailed analytics  
**Setup**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init appdistribution

# Deploy
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers" \
  --release-notes "Week 1 security testing build"
```

### Option 3: Direct APK Distribution

**Pros**: Immediate, no setup  
**Cons**: Manual updates, no analytics

**Steps**:
1. Upload APK to Google Drive / Dropbox
2. Share link with testers
3. Instruct testers to enable "Install from unknown sources"

---

## 📱 Tester Setup Instructions

### For Testers

**Installation**:
1. Download APK from [distribution link]
2. Enable **Settings → Security → Unknown Sources** (if direct APK)
3. Install APK
4. Open app and create account

**Testing Focus**:
- ✅ Daily check-ins (test rate limiting: 6+ in 1 hour)
- ✅ Enabling/disabling blocker VPN
- ✅ Attempting check-in with external VPN (should block)
- ✅ Relapse flow (trigger, reflection)
- ✅ Islamic content browsing
- ✅ Streak accuracy after missed days
- ⚠️ Offline mode (disable WiFi, check in, reconnect)

---

## 🧪 Week 1 Testing Checklist

### Day 1-2: Basic Functionality
- [ ] Sign up / Login works
- [ ] VPN blocker starts successfully
- [ ] Daily check-in logs correctly
- [ ] Streak increments properly
- [ ] Islamic content loads

### Day 3-4: Security Features
- [ ] External VPN blocking works
- [ ] Rate limiting enforced (6th check-in fails)
- [ ] Invalid mood values rejected
- [ ] Notes over 500 chars rejected

### Day 5-6: Edge Cases
- [ ] Offline check-ins sync correctly
- [ ] Missed day resets streak properly
- [ ] Relapse resets streak to 0
- [ ] Multiple devices (same account) sync

### Day 7: Final Verification
- [ ] Review security_events in Supabase
- [ ] Check rate_limits table for abuse patterns
- [ ] Verify no crash reports
- [ ] Collect user feedback

---

## 📊 Monitoring & Analytics

### Supabase Dashboard

**Daily Checks**:
1. **Authentication** → Active users count
2. **Database** → Security events table
3. **Database** → Rate limits violations

**Queries to Run**:
```sql
-- Most active users
SELECT user_id, COUNT(*) as checkins 
FROM daily_log 
WHERE date > NOW() - INTERVAL '7 days' 
GROUP BY user_id 
ORDER BY checkins DESC;

-- Security events summary
SELECT event_type, COUNT(*) 
FROM security_events 
WHERE created_at > NOW() - INTERVAL '7 days' 
GROUP BY event_type;

-- Rate limit violations
SELECT action_type, COUNT(*) as violations
FROM rate_limits 
WHERE attempt_count >= 5 
GROUP BY action_type;
```

---

## 🐛 Known Issues & Workarounds

### Issue 1: Emulator Detection
**Problem**: App blocks on Android emulator  
**Workaround**: Use physical device for testing

### Issue 2: Rate Limiting During Testing
**Problem**: Testers hit limits quickly  
**Temporary Fix**:
```sql
-- Clear rate limits for specific user
DELETE FROM rate_limits WHERE user_id = 'USER_UUID';
```

### Issue 3: VPN Conflicts
**Problem**: Corporate VPN may trigger blocking  
**Workaround**: Add exception for specific VPN in `NetworkUtils.kt`

---

## 🔄 Rollback Plan

If critical issues found:

1. **Pause new signups**:
```sql
-- Temporary block (run in Supabase SQL)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Signups temporarily disabled';
END;
$$ LANGUAGE plpgsql;
```

2. **Notify active users** (via email/in-app)

3. **Revert SQL migrations** (if needed):
```sql
-- Example: Remove rate limiting
DROP FUNCTION IF EXISTS check_rate_limit CASCADE;
```

---

## 📞 Support Contact

**For Critical Issues**:
- Email: [your-email@domain.com]
- Response time: < 4 hours

**For Feedback**:
- Google Form: [link]
- Discord: [invite link]

---

## ✅ Post-Week 1 Review

**Collect**:
- Crash logs (if any)
- User feedback survey results
- Supabase analytics summary
- Security events analysis

**Decide**:
- [ ] Extend to Week 2 public beta
- [ ] Fix critical bugs first
- [ ] Launch to production

---

**Deployment Prepared By**: Antigravity AI  
**Date**: January 9, 2026  
**Version**: 1.0.0-beta
