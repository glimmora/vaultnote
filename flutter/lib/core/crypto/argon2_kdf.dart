import 'dart:typed_data';
import 'package:argon2/argon2.dart';
import 'secure_random.dart';

/// Argon2id Key Derivation Function
/// Parameters: m=65536 (memory), t=3 (iterations), p=4 (parallelism)
class Argon2KDF {
  static const int memoryCost = 65536; // 64 MB
  static const int timeCost = 3;
  static const int parallelism = 4;
  static const int derivedKeyLength = 32; // 256 bits
  static const int minSaltLength = 16;
  static const int maxPasswordLength = 1024;

  /// Derive a 256-bit key from password and salt
  Future<Uint8List> deriveKey(String password, Uint8List salt) async {
    try {
      if (password.isEmpty) {
        throw ArgumentError('Password cannot be empty');
      }
      if (password.length > maxPasswordLength) {
        throw ArgumentError('Password too long (max $maxPasswordLength chars)');
      }
      if (salt.isEmpty) {
        throw ArgumentError('Salt cannot be empty');
      }
      if (salt.length < minSaltLength) {
        throw ArgumentError('Salt must be at least $minSaltLength bytes, got ${salt.length}');
      }

      final params = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        iterations: timeCost,
        memory: memoryCost,
        lanes: parallelism,
      );

      final generator = Argon2BytesGenerator();
      generator.init(params);

      final passwordBytes = Uint8List.fromList(password.codeUnits);
      final result = Uint8List(derivedKeyLength);
      generator.generateBytes(passwordBytes, result, 0, derivedKeyLength);

      return result;
    } catch (e) {
      throw Exception('Key derivation failed: $e');
    }
  }

  /// Generate a new random salt
  Uint8List generateSalt() {
    return SecureRandom.bytes(32);
  }

  /// Verify a password against a stored hash
  Future<bool> verify(String password, Uint8List hash, Uint8List salt) async {
    if (password.isEmpty || hash.isEmpty || salt.isEmpty) {
      return false;
    }
    final derivedKey = await deriveKey(password, salt);
    return _constantTimeCompare(derivedKey, hash);
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}