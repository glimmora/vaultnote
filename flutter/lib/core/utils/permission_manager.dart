import 'package:permission_handler/permission_handler.dart';

/// Handles all runtime permission requests with proper error handling
class PermissionManager {
  static Future<bool> requestCamera() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        return false;
      }

      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestBiometric() async {
    try {
      final status = await Permission.biometric.status;
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        return false;
      }

      final result = await Permission.biometric.request();
      return result.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isCameraGranted() async {
    try {
      return await Permission.camera.status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isBiometricGranted() async {
    try {
      return await Permission.biometric.status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
    }
  }
}
