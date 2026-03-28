import 'package:flutter_test/flutter_test.dart';
import 'package:vaultnote/core/crypto/secure_random.dart';

void main() {
  group('SecureRandom', () {
    test('bytes should return correct length', () {
      final bytes = SecureRandom.bytes(32);
      expect(bytes.length, equals(32));
    });

    test('bytes should return different values each time', () {
      final bytes1 = SecureRandom.bytes(32);
      final bytes2 = SecureRandom.bytes(32);
      expect(bytes1, isNot(equals(bytes2)));
    });

    test('nextInt should return value in range', () {
      for (int i = 0; i < 100; i++) {
        final value = SecureRandom.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('nextBool should return boolean', () {
      for (int i = 0; i < 100; i++) {
        final value = SecureRandom.nextBool();
        expect(value, isA<bool>());
      }
    });
  });
}