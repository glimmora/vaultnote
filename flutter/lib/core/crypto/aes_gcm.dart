import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'secure_random.dart' as secure_random;

/// AES-256-GCM Encryption/Decryption
class AESGCM {
  static const int keyLength = 32; // 256 bits
  static const int ivLength = 12; // 96 bits
  static const int authTagLength = 16;

  /// Encrypt plaintext using AES-256-GCM
  /// Returns encrypted data with appended auth tag
  static (Uint8List ciphertext, Uint8List iv, Uint8List authTag) encrypt(
    Uint8List plaintext,
    Uint8List key, {
    Uint8List? iv,
  }) {
    if (key.length != keyLength) {
      throw ArgumentError('Key must be 32 bytes (256 bits)');
    }

    iv ??= secure_random.SecureRandom.bytes(ivLength);
    if (iv.length != ivLength) {
      throw ArgumentError('IV must be 12 bytes (96 bits)');
    }

    final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: IV(iv));
    
    // encrypt package includes auth tag in the encrypted result
    // We need to extract it (last 16 bytes)
    final encryptedBytes = encrypted.bytes;
    final ciphertext = Uint8List.fromList(
      encryptedBytes.sublist(0, encryptedBytes.length - authTagLength),
    );
    final authTag = Uint8List.fromList(
      encryptedBytes.sublist(encryptedBytes.length - authTagLength),
    );

    return (ciphertext, iv, authTag);
  }

  /// Decrypt ciphertext using AES-256-GCM
  /// Verifies auth tag automatically
  static Uint8List decrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
    Uint8List authTag,
  ) {
    if (key.length != keyLength) {
      throw ArgumentError('Key must be 32 bytes (256 bits)');
    }

    if (iv.length != ivLength) {
      throw ArgumentError('IV must be 12 bytes (96 bits)');
    }

    if (authTag.length != authTagLength) {
      throw ArgumentError('Auth tag must be 16 bytes');
    }

    final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));

    // Combine ciphertext and auth tag for decryption
    final combined = Uint8List(ciphertext.length + authTag.length);
    combined.setAll(0, ciphertext);
    combined.setAll(ciphertext.length, authTag);

    try {
      final decrypted = encrypter.decryptBytes(Encrypted(combined), iv: IV(iv));
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: authentication tag verification failed');
    }
  }
}
