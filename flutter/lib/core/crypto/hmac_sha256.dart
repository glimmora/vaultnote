import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// HMAC-SHA256 for integrity verification
class HMACSHA256 {
  static const int keyLength = 32;
  static const int hashLength = 32;

  /// Compute HMAC-SHA256 of data
  static Uint8List compute(Uint8List data, Uint8List key) {
    if (key.length != keyLength) {
      throw ArgumentError('Key must be 32 bytes (256 bits)');
    }

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Verify HMAC-SHA256
  static bool verify(Uint8List data, Uint8List key, Uint8List expectedHmac) {
    final computedHmac = compute(data, key);
    return _constantTimeCompare(computedHmac, expectedHmac);
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    final result = 0;
    for (final i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
