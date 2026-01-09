import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blockerRepositoryProvider = Provider((ref) => BlockerRepository());

class BlockerRepository {
  static const platform = MethodChannel('com.example.prevention/blocker');

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
}
