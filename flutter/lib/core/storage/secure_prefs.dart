import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Secure preferences wrapper using flutter_secure_storage
/// Backed by Android Keystore / iOS Keychain
class SecurePrefs {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _saltKey = 'vnc_salt';
  static const String _verifyKey = 'vnc_key_verify';
  static const String _pinKey = 'vnc_pin_hash';
  static const String _biometricEnabledKey = 'vnc_biometric_enabled';
  static const String _autoLockMinutesKey = 'vnc_autolock_minutes';
  static const String _themeModeKey = 'vnc_theme_mode';

  /// Store the KDF salt
  Future<void> setSalt(Uint8List salt) async {
    final encoded = base64Encode(salt);
    await _storage.write(key: _saltKey, value: encoded);
  }

  /// Retrieve the KDF salt
  Future<Uint8List?> getSalt() async {
    final encoded = await _storage.read(key: _saltKey);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  /// Store verification hash for password
  Future<void> setVerifyHash(Uint8List hash) async {
    final encoded = base64Encode(hash);
    await _storage.write(key: _verifyKey, value: encoded);
  }

  /// Retrieve verification hash
  Future<Uint8List?> getVerifyHash() async {
    final encoded = await _storage.read(key: _verifyKey);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  /// Store PIN hash (for PIN unlock)
  Future<void> setPinHash(String hash) async {
    await _storage.write(key: _pinKey, value: hash);
  }

  /// Retrieve PIN hash
  Future<String?> getPinHash() async {
    return await _storage.read(key: _pinKey);
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Set biometric enabled status
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled ? 'true' : 'false');
  }

  /// Get auto-lock timeout in minutes
  Future<int> getAutoLockMinutes() async {
    final value = await _storage.read(key: _autoLockMinutesKey);
    return int.tryParse(value ?? '5') ?? 5;
  }

  /// Set auto-lock timeout
  Future<void> setAutoLockMinutes(int minutes) async {
    await _storage.write(key: _autoLockMinutesKey, value: minutes.toString());
  }

  /// Get theme mode (0=system, 1=light, 2=dark)
  Future<int> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return int.tryParse(value ?? '0') ?? 0;
  }

  /// Set theme mode
  Future<void> setThemeMode(int mode) async {
    await _storage.write(key: _themeModeKey, value: mode.toString());
  }

  /// Clear all secure data
  Future<void> clearAll() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _verifyKey);
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _autoLockMinutesKey);
  }
}
