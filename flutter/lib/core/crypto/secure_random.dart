import 'dart:math';
import 'dart:typed_data';

/// Cryptographically secure random number generator wrapper
class SecureRandom {
  static final Random _random = Random.secure();

  /// Generate [length] cryptographically secure random bytes
  static Uint8List bytes(int length) {
    final result = Uint8List(length);
    for (int i = 0; i < length; i++) {
      result[i] = _random.nextInt(256);
    }
    return result;
  }

  /// Generate a random integer in range [0, max)
  static int nextInt(int max) {
    return _random.nextInt(max);
  }

  /// Generate a random boolean
  static bool nextBool() {
    return _random.nextBool();
  }
}