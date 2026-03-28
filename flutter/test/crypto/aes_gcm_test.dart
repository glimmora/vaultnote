import 'package:flutter_test/flutter_test.dart';
import 'package:vaultnote/core/crypto/aes_gcm.dart';
import 'package:vaultnote/core/crypto/secure_random.dart';

void main() {
  group('AESGCM', () {
    test('encrypt and decrypt should work correctly', () {
      final key = SecureRandom.bytes(32);
      final plaintext = SecureRandom.bytes(100);

      final (ciphertext, iv, authTag) = AESGCM.encrypt(plaintext, key);
      final decrypted = AESGCM.decrypt(ciphertext, key, iv, authTag);

      expect(decrypted, equals(plaintext));
    });

    test('encrypt should generate different IV each time', () {
      final key = SecureRandom.bytes(32);
      final plaintext = SecureRandom.bytes(100);

      final (_, iv1, _) = AESGCM.encrypt(plaintext, key);
      final (_, iv2, _) = AESGCM.encrypt(plaintext, key);

      expect(iv1, isNot(equals(iv2)));
    });

    test('decrypt with wrong key should throw', () {
      final key1 = SecureRandom.bytes(32);
      final key2 = SecureRandom.bytes(32);
      final plaintext = SecureRandom.bytes(100);

      final (ciphertext, iv, authTag) = AESGCM.encrypt(plaintext, key1);

      expect(
        () => AESGCM.decrypt(ciphertext, key2, iv, authTag),
        throwsException,
      );
    });

    test('decrypt with wrong auth tag should throw', () {
      final key = SecureRandom.bytes(32);
      final plaintext = SecureRandom.bytes(100);

      final (ciphertext, iv, authTag) = AESGCM.encrypt(plaintext, key);
      final wrongAuthTag = SecureRandom.bytes(16);

      expect(
        () => AESGCM.decrypt(ciphertext, key, iv, wrongAuthTag),
        throwsException,
      );
    });

    test('encrypt with invalid key length should throw', () {
      final invalidKey = SecureRandom.bytes(16); // 128 bits instead of 256
      final plaintext = SecureRandom.bytes(100);

      expect(
        () => AESGCM.encrypt(plaintext, invalidKey),
        throwsArgumentError,
      );
    });

    test('encrypt with invalid IV length should throw', () {
      final key = SecureRandom.bytes(32);
      final invalidIv = SecureRandom.bytes(8); // 64 bits instead of 96
      final plaintext = SecureRandom.bytes(100);

      expect(
        () => AESGCM.encrypt(plaintext, key, iv: invalidIv),
        throwsArgumentError,
      );
    });
  });
}