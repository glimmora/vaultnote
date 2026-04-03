import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// HMAC-SHA256 for integrity verification
class HMACSHA256 {
  static const int keyLength = 32;
  static const int hashLength = 32;

  /// Compute HMAC-SHA256 of data
  static Uint8List compute(Uint8List data, Uint8List key) {
    if (data.isEmpty) {
      throw ArgumentError('Data cannot be empty');
    }
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    if (key.length != keyLength) {
      throw ArgumentError('Key must be 32 bytes (256 bits), got ${key.length}');
    }

    try {
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(data);
      return Uint8List.fromList(digest.bytes);
    } catch (e) {
      throw Exception('HMAC computation failed: $e');
    }
  }

  /// Verify HMAC-SHA256
  static bool verify(Uint8List data, Uint8List key, Uint8List expectedHmac) {
    if (data.isEmpty || key.isEmpty || expectedHmac.isEmpty) {
      return false;
    }
    try {
      final computedHmac = compute(data, key);
      return _constantTimeCompare(computedHmac, expectedHmac);
    } catch (e) {
      return false;
    }
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
