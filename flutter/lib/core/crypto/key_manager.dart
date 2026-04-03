import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'argon2_kdf.dart';
import 'hmac_sha256.dart';

/// Manages in-memory encryption keys
/// Keys are stored in hardware-backed secure storage and memory
class KeyManager {
  Uint8List? _masterKey;
  Uint8List? _hmacKey;
  bool _isUnlocked = false;
  int _unlockTimestamp = 0;
  int _autoLockTimeoutMs = 300000; // 5 minutes default

  final Argon2KDF _kdf = Argon2KDF();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  bool get isUnlocked => _isUnlocked;
  Uint8List? get masterKey => _masterKey;
  Uint8List? get hmacKey => _hmacKey;

  /// Unlock with password and salt
  Future<bool> unlock(String password, Uint8List salt, Uint8List? storedVerifyHash) async {
    try {
      if (password.isEmpty) {
        throw ArgumentError('Password cannot be empty');
      }
      if (salt.isEmpty) {
        throw ArgumentError('Salt cannot be empty');
      }

      final key = await _kdf.deriveKey(password, salt);
      _masterKey = key;

      // Derive HMAC key from master key
      _hmacKey = _deriveHmacKey(key);

      // Verify if we have a stored verification hash
      if (storedVerifyHash != null) {
        final testVector = _createTestVector(key);
        if (!_constantTimeCompare(testVector, storedVerifyHash)) {
          clearKey();
          return false;
        }
      }

      _isUnlocked = true;
      _unlockTimestamp = DateTime.now().millisecondsSinceEpoch;
      return true;
    } catch (e) {
      clearKey();
      return false;
    }
  }

  /// Check if auto-lock timeout has been exceeded
  bool isAutoLocked() {
    if (!_isUnlocked || _autoLockTimeoutMs <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _unlockTimestamp) > _autoLockTimeoutMs;
  }

  /// Set auto-lock timeout in milliseconds (0 to disable)
  void setAutoLockTimeout(int timeoutMs) {
    _autoLockTimeoutMs = timeoutMs;
  }

  /// Touch to reset auto-lock timer
  void touch() {
    if (_isUnlocked) {
      _unlockTimestamp = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Save encrypted salt to secure storage
  Future<void> saveSalt(Uint8List salt) async {
    await _secureStorage.write(key: 'vnc_salt', value: base64Encode(salt));
  }

  /// Load salt from secure storage
  Future<Uint8List?> loadSalt() async {
    final b64 = await _secureStorage.read(key: 'vnc_salt');
    if (b64 == null) return null;
    return Uint8List.fromList(base64Decode(b64));
  }

  /// Save verification hash to secure storage
  Future<void> saveVerifyHash(Uint8List hash) async {
    await _secureStorage.write(key: 'vnc_key_verify', value: base64Encode(hash));
  }

  /// Load verification hash from secure storage
  Future<Uint8List?> loadVerifyHash() async {
    final b64 = await _secureStorage.read(key: 'vnc_key_verify');
    if (b64 == null) return null;
    return Uint8List.fromList(base64Decode(b64));
  }

  /// Create verification hash for password verification
  Uint8List createVerifyHash() {
    if (_masterKey == null) {
      throw StateError('KeyManager not unlocked');
    }
    return _createTestVector(_masterKey!);
  }

  Uint8List _createTestVector(Uint8List key) {
    final testVector = Uint8List.fromList(utf8.encode('VNC_VERIFY'));
    return HMACSHA256.compute(testVector, key);
  }

  Uint8List _deriveHmacKey(Uint8List masterKey) {
    final hmacKeySeed = Uint8List.fromList(utf8.encode('VNC_HMAC_KEY'));
    return HMACSHA256.compute(hmacKeySeed, masterKey);
  }

  /// Clear all keys from memory with secure zero-fill
  void clearKey() {
    if (_masterKey != null) {
      for (int i = 0; i < _masterKey!.length; i++) {
        _masterKey![i] = 0;
      }
      _masterKey = null;
    }
    if (_hmacKey != null) {
      for (int i = 0; i < _hmacKey!.length; i++) {
        _hmacKey![i] = 0;
      }
      _hmacKey = null;
    }
    _isUnlocked = false;
    _unlockTimestamp = 0;
  }

  /// Lock the key manager
  void lock() {
    clearKey();
  }

  /// Dispose and clear resources
  void dispose() {
    clearKey();
  }

  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
