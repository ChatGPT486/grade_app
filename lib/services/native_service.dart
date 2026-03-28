import 'package:flutter/services.dart';

/// Communicates with the native Kotlin MainActivity
/// via a Flutter MethodChannel.
class NativeService {
  static const _channel =
      MethodChannel('com.example.grade_calculator/info');

  /// Returns device brand, model, Android version, SDK level
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, String>('getDeviceInfo');
      return result ?? {};
    } on PlatformException catch (e) {
      return {'error': e.message ?? 'Unknown error'};
    }
  }

  /// Returns the app version string from AndroidManifest
  static Future<String> getAppVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getAppVersion');
      return result ?? '1.0.0';
    } on PlatformException {
      return '1.0.0';
    }
  }
}