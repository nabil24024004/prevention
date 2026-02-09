# Testing Instructions - 5.0.0 Stable Release

## 🎯 Welcome Beta Tester!

Thank you for helping test the **Prevention** app. This guide will walk you through the testing process.

---

## 📱 Installation

### Step 1: Download APK
- Download from: [Link provided by admin]
- File: `app-release.apk` (52.4 MB)

### Step 2: Enable Installation
1. Go to **Settings** → **Security**
2. Enable **Install Unknown Apps** (or **Unknown Sources** on older Android)
3. Allow your browser/file manager to install apps

### Step 3: Install
1. Open the downloaded APK file
2. Tap **Install**
3. Wait for installation to complete
4. Tap **Open**

---

## 👤 Account Setup

### Create Account
1. Open app
2. Tap **Sign Up**
3. Enter:
   - Full Name
   - Email address
   - Password (min 8 characters)
4. Verify email (check inbox/spam)
5. Log in

---

## ✅ Daily Testing Routine

### Morning (Day 1-7)

**5-Minute Test**:
1. ✅ Open app
2. ✅ Complete daily check-in
   - Select mood: Great / Good / Okay / Struggling
   - Add optional notes
3. ✅ Verify streak increments
4. ✅ Browse Islamic content (1-2 articles)

### Evening Check

**Test Blocker**:
1. ✅ Enable VPN blocker (if not already)
2. ✅ Try accessing blocked site → Should be blocked
3. ✅ Disable blocker → Sites accessible
4. ✅ Re-enable blocker

---

## 🧪 Feature Tests

### Test 1: VPN Detection (Day 2)

**Steps**:
1. Install a VPN app (e.g., Proton VPN, NordVPN)
2. Enable the external VPN
3. Try to complete daily check-in
4. **Expected**: Error message "External VPN detected"
5. Disable VPN and try again
6. **Expected**: Check-in succeeds

### Test 2: Rate Limiting (Day 3)

**Steps**:
1. Complete daily check-in (1st time)
2. Try to check in again immediately (will update existing)
3. Repeat 5 more times within 1 hour
4. **Expected**: 6th attempt shows "Rate limit exceeded"
5. Wait 1 hour, try again
6. **Expected**: Check-in succeeds

### Test 3: Input Validation (Day 4)

**Steps**:
1. Try check-in with very long notes (copy/paste 600+ characters)
2. **Expected**: Error "Notes too long. Maximum 500 characters"

### Test 4: Relapse Flow (Day 5)

**Steps**:
1. Tap **I Relapsed** button
2. Complete the flow:
   - Read "shame" message
   - Select trigger (stress, boredom, etc.)
   - Write reflection (mandatory)
3. **Expected**: Streak resets to 0
4. New check-in starts fresh streak

### Test 5: Offline Mode (Day 6)

**Steps**:
1. Turn OFF WiFi and mobile data
2. Complete daily check-in
3. **Expected**: "Offline - will sync later"
4. Turn ON internet
5. **Expected**: Check-in syncs automatically
6. Verify streak updated correctly

### Test 6: Multi-Device (Day 7)

**Optional** if you have 2 devices:
1. Install on Device 2
2. Log in with same account
3. Complete check-in on Device 1
4. Open Device 2
5. **Expected**: Streak syncs within 1 minute

---

## 🐛 Bug Reporting

### If App Crashes

**Report**:
1. Note what you were doing
2. Email: [support-email@domain.com]
3. Include:
   - Device model
   - Android version
   - Steps to reproduce

### If Feature Doesn't Work

**Report**:
1. Feature name
2. Expected behavior
3. Actual behavior
4. Screenshots (if possible)

---

## 📝 Feedback Form

**At End of Week 1**:
- Survey link: [Google Form link]
- Time: ~5 minutes
- Topics:
  - App usability
  - Feature requests
  - Bug severity
  - Overall rating

---

## ⚠️ Known Limitations

- **Emulators**: App may not work on Android emulator (use real device)
- **Corporate VPNs**: May trigger VPN detection (expected)
- **Rate Limits**: Intentionally strict for testing

---

## 🎯 Testing Goals

**Help us verify**:
- ✅ VPN blocker works reliably
- ✅ Streak tracking is accurate
- ✅ Security features prevent cheating
- ✅ App is stable (no crashes)
- ✅ User experience is smooth

---

## 📞 Support

**Questions?**
- Email: [support email]
- Response time: < 24 hours

**Urgent Issues?**
- Discord: [invite link]

---

**Thank you for testing! Your feedback will make this app better for everyone.**  

---

**Version**: 5.0.0 Stable Release  
**Last Updated**: February 9, 2026
