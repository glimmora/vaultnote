import 'dart:typed_data';
import 'dart:convert';
import 'argon2_kdf.dart';
import 'hmac_sha256.dart';
import 'secure_random.dart';

/// Manages in-memory encryption keys
/// Keys are NEVER written to disk and are cleared on lock/dispose
class KeyManager {
  Uint8List? _masterKey;
  Uint8List? _hmacKey;
  bool _isUnlocked = false;

  final Argon2KDF _kdf = Argon2KDF();

  bool get isUnlocked => _isUnlocked;
  Uint8List? get masterKey => _masterKey;
  Uint8List? get hmacKey => _hmacKey;

  /// Unlock with password and salt
  Future<bool> unlock(String password, Uint8List salt, Uint8List? storedVerifyHash) async {
    try {
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
      return true;
    } catch (e) {
      clearKey();
      return false;
    }
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

  /// Clear all keys from memory
  void clearKey() {
    if (_masterKey != null) {
      // Zero-fill before clearing
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
