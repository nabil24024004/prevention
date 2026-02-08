# Xcode Setup Guide for Prevention App (Beginner)

## Prerequisites

- **Mac computer** (Xcode only runs on macOS)
- **Xcode 15+** - Download free from Mac App Store
- **Apple ID** (free, for Simulator testing)

---

## Step 1: Install Xcode

1. Open **Mac App Store**
2. Search "Xcode"
3. Click **Get** → **Install** (15+ GB download)
4. After install, open Xcode once to accept license agreements

---

## Step 2: Open the Project

```bash
# In Terminal, navigate to your project
cd "/Volumes/local disk/Prevention"

# Open the iOS workspace
open ios/Runner.xcworkspace
```

> ⚠️ Always open `.xcworkspace`, NOT `.xcodeproj`

---

## Step 3: Select a Simulator

1. In Xcode's top toolbar, click the device dropdown (shows "Any iOS Device")
2. Under **iOS Simulators**, select **iPhone 15** or similar
3. Wait for simulator to download if prompted

---

## Step 4: Build & Run (Basic Test)

1. Press **⌘ + R** (Command + R) or click the **▶ Play** button
2. Wait for build to complete (first build takes 2-5 minutes)
3. Simulator will launch with your app

**Expected:** App should launch and show the onboarding/welcome screen

---

## Step 5: Add the PacketTunnel Extension Target

> ⚠️ This step is required for VPN/content blocking to work

1. In Xcode, go to **File → New → Target**
2. Search for "Network Extension"
3. Select **Network Extension** → **Next**
4. Configure:
   - Product Name: `PacketTunnel`
   - Team: Select your Apple ID
   - Bundle Identifier: `com.prevention.prevention.PacketTunnel`
   - Language: **Swift**
   - Provider Type: **Packet Tunnel**
5. Click **Finish**
6. When prompted "Activate scheme?", click **Cancel** (stay on Runner scheme)

---

## Step 6: Replace Generated Files

Xcode created placeholder files. Replace them with ours:

1. In Xcode's left sidebar, find the **PacketTunnel** folder
2. Right-click on `PacketTunnelProvider.swift` → **Delete** → Move to Trash
3. Right-click on **PacketTunnel** folder → **Add Files to "PacketTunnel"**
4. Navigate to `ios/PacketTunnel/` and select:
   - `PacketTunnelProvider.swift`
   - `Info.plist`
5. Make sure "Copy items if needed" is **unchecked**
6. Click **Add**

---

## Step 7: Enable Capabilities

1. In left sidebar, click **Runner** (blue icon at top)
2. Select **Runner** target in the middle panel
3. Click **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Add:
   - **App Groups** → Add group: `group.com.prevention.prevention`
   - **Network Extensions** (requires paid Apple Developer account)

> 💡 For Simulator testing, skip Network Extensions capability - VPN won't work on Simulator anyway

---

## Step 8: Run on Simulator

1. Make sure **Runner** scheme is selected (not PacketTunnel)
2. Select an **iPhone simulator** from device dropdown
3. Press **⌘ + R**

**What works on Simulator:**
- ✅ All UI screens
- ✅ Supabase authentication
- ✅ Streak tracking
- ✅ Notifications
- ❌ VPN/Browser Protection (requires real device + entitlements)

---

## Step 9: Test on Real Device (Optional - Requires Apple Developer Account)

1. Connect iPhone via USB
2. On iPhone: **Settings → Privacy → Developer Mode → Enable**
3. In Xcode, select your iPhone from device dropdown
4. In **Signing & Capabilities**, select your Team
5. Press **⌘ + R**
6. On iPhone, go to **Settings → General → VPN & Device Management** → Trust the developer

---

## Common Errors & Fixes

| Error | Solution |
|-------|----------|
| "No team selected" | Signing & Capabilities → Select your Apple ID |
| "Provisioning profile" error | Sign in with Apple ID in Xcode → Preferences → Accounts |
| "NetworkExtension not available" | Need paid Apple Developer account ($99/year) |
| Build failed with framework error | Run `flutter pub get` then try again |
| Simulator won't launch | Xcode → Product → Clean Build Folder (⇧⌘K) |

---

## Quick Reference

| Action | Shortcut |
|--------|----------|
| Build & Run | ⌘ + R |
| Stop | ⌘ + . |
| Clean Build | ⇧ + ⌘ + K |
| Show Console | ⇧ + ⌘ + C |

---

## Testing Checklist

- [ ] App launches on Simulator
- [ ] Can navigate through onboarding
- [ ] Can sign up / log in
- [ ] Dashboard loads correctly
- [ ] Notifications permission prompt appears
- [ ] (Real device only) Browser Protection toggle works
