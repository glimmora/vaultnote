import 'package:flutter_test/flutter_test.dart';
import 'package:vaultnote/core/crypto/hmac_sha256.dart';
import 'package:vaultnote/core/crypto/secure_random.dart';

void main() {
  group('HMACSHA256', () {
    test('compute should return correct length', () {
      final key = SecureRandom.bytes(32);
      final data = SecureRandom.bytes(100);

      final hmac = HMACSHA256.compute(data, key);

      expect(hmac.length, equals(32));
    });

    test('compute should be deterministic', () {
      final key = SecureRandom.bytes(32);
      final data = SecureRandom.bytes(100);

      final hmac1 = HMACSHA256.compute(data, key);
      final hmac2 = HMACSHA256.compute(data, key);

      expect(hmac1, equals(hmac2));
    });

    test('compute with different data should return different result', () {
      final key = SecureRandom.bytes(32);
      final data1 = SecureRandom.bytes(100);
      final data2 = SecureRandom.bytes(100);

      final hmac1 = HMACSHA256.compute(data1, key);
      final hmac2 = HMACSHA256.compute(data2, key);

      expect(hmac1, isNot(equals(hmac2)));
    });

    test('compute with different key should return different result', () {
      final key1 = SecureRandom.bytes(32);
      final key2 = SecureRandom.bytes(32);
      final data = SecureRandom.bytes(100);

      final hmac1 = HMACSHA256.compute(data, key1);
      final hmac2 = HMACSHA256.compute(data, key2);

      expect(hmac1, isNot(equals(hmac2)));
    });

    test('verify should return true for valid HMAC', () {
      final key = SecureRandom.bytes(32);
      final data = SecureRandom.bytes(100);

      final hmac = HMACSHA256.compute(data, key);
      final isValid = HMACSHA256.verify(data, key, hmac);

      expect(isValid, isTrue);
    });

    test('verify should return false for invalid HMAC', () {
      final key = SecureRandom.bytes(32);
      final data = SecureRandom.bytes(100);

      final wrongHmac = SecureRandom.bytes(32);
      final isValid = HMACSHA256.verify(data, key, wrongHmac);

      expect(isValid, isFalse);
    });
  });
}