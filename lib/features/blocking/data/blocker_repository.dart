import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final blockerRepositoryProvider = Provider((ref) => BlockerRepository());

class BlockerRepository {
  static const platform = MethodChannel('com.example.prevention/blocker');

  /// Cached panic seconds for router-to-screen communication
  static int cachedPanicSeconds = 0;

  Future<bool> isVpnActive() async {
    try {
      final bool result = await platform.invokeMethod('isVpnActive');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> startBlocking() async {
    try {
      await platform.invokeMethod('startVpn');
    } on PlatformException catch (e) {
      throw Exception('Failed to start blocking: ${e.message}');
    }
  }

  Future<void> stopBlocking() async {
    try {
      await platform.invokeMethod('stopVpn');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop blocking: ${e.message}');
    }
  }

  Future<bool> checkDevMode() async {
    try {
      final bool result = await platform.invokeMethod('checkDevMode');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isExternalVpnActive() async {
    try {
      final bool result = await platform.invokeMethod('isExternalVpnActive');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isEmulator() async {
    try {
      final bool result = await platform.invokeMethod('isEmulator');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isRooted() async {
    try {
      final bool result = await platform.invokeMethod('isRooted');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getTamperStatus() async {
    try {
      final result = await platform.invokeMethod('getTamperStatus');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (_) {
      return {
        'dev_mode': false,
        'emulator': false,
        'rooted': false,
        'debug_build': false,
      };
    }
  }

  // ==================== PANIC MODE LOCKDOWN ====================

  static const String _panicEndTimeKey = 'panic_end_timestamp';

  /// Start Android screen pinning (locks app to foreground)
  /// User will be prompted to confirm the first time
  Future<bool> startScreenPin() async {
    try {
      await platform.invokeMethod('startScreenPin');
      return true;
    } on PlatformException catch (e) {
      // User may have denied or it's not supported
      print('Screen pin failed: ${e.message}');
      return false;
    }
  }

  /// Stop screen pinning
  Future<bool> stopScreenPin() async {
    try {
      await platform.invokeMethod('stopScreenPin');
      return true;
    } on PlatformException catch (e) {
      print('Stop screen pin failed: ${e.message}');
      return false;
    }
  }

  /// Set panic mode active with end timestamp and start screen pinning
  Future<void> setPanicModeActive(int durationSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now()
        .add(Duration(seconds: durationSeconds))
        .millisecondsSinceEpoch;
    await prefs.setInt(_panicEndTimeKey, endTime);
    // Notify Android to enable lockdown
    try {
      await platform.invokeMethod('setPanicLockdown', {'active': true});
    } on PlatformException catch (_) {
      // Non-critical if native side isn't ready
    }
    // Start screen pinning for reliable lockdown
    await startScreenPin();
  }

  /// Clear panic mode and stop screen pinning
  Future<void> clearPanicMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_panicEndTimeKey);
    // Stop screen pinning first
    await stopScreenPin();
    // Notify Android to disable lockdown
    try {
      await platform.invokeMethod('setPanicLockdown', {'active': false});
    } on PlatformException catch (_) {
      // Non-critical
    }
  }

  /// Get remaining panic seconds, or 0 if not active
  Future<int> getPanicSecondsRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = prefs.getInt(_panicEndTimeKey);
    if (endTime == null) return 0;

    final remaining = endTime - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      await clearPanicMode();
      return 0;
    }
    return (remaining / 1000).ceil();
  }

  /// Check if panic mode is currently active
  Future<bool> isPanicModeActive() async {
    return (await getPanicSecondsRemaining()) > 0;
  }
}
