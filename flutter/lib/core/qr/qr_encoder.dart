import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../crypto/argon2_kdf.dart';
import '../crypto/aes_gcm.dart';
import '../crypto/hmac_sha256.dart';
import '../crypto/secure_random.dart';
import '../../domain/entities/note.dart';

/// QR Code encoder - converts note to encrypted QR chunks
/// 
/// Format per QR:
/// Header: "VNQ:v1:{index}/{total}:{crc32}"
/// Payload: Base64url encoded encrypted data
/// 
/// First QR contains salt (32 bytes) + iv (12 bytes)
/// Last QR contains final HMAC (32 bytes)
class QREncoder {
  static const int maxChunkSize = 600; // bytes per QR
  static const String qrVersion = 'v1';

  /// Export note as QR code strings
  Future<List<String>> exportNoteAsQR(Note note, String password) async {
    // Serialize and compress
    final payload = note.toJson();
    final jsonString = jsonEncode(payload);
    final compressed = GZipEncoder().encode(Uint8List.fromList(utf8.encode(jsonString)));
    if (compressed == null) {
      throw Exception('Compression failed');
    }

    // Generate salt and IV
    final salt = SecureRandom.bytes(32);
    final iv = SecureRandom.bytes(12);

    // Derive key from password
    final kdf = Argon2KDF();
    final key = await kdf.deriveKey(password, salt);

    // Encrypt
    final (ciphertext, _, authTag) = AESGCM.encrypt(
      Uint8List.fromList(compressed),
      key,
      iv: iv,
    );

    // Compute HMAC
    final hmacKey = _deriveHmacKey(key);
    final dataToHmac = Uint8List.fromList([
      ...salt,
      ...iv,
      ...ciphertext,
      ...authTag,
    ]);
    final hmac = HMACSHA256.compute(dataToHmac, hmacKey);

    // Combine all data: salt + iv + ciphertext + authTag + hmac
    final fullData = Uint8List.fromList([
      ...salt,
      ...iv,
      ...ciphertext,
      ...authTag,
      ...hmac,
    ]);

    // Split into chunks
    final chunks = _splitIntoChunks(fullData, maxChunkSize);
    final total = chunks.length;

    // Generate QR strings
    final qrStrings = <String>[];
    for (var i = 0; i < chunks.length; i++) {
      final header = 'VNQ:$qrVersion:${i + 1}/$total';
      final encoded = base64Url.encode(chunks[i]);
      qrStrings.add('$header:$encoded');
    }

    return qrStrings;
  }

  List<Uint8List> _splitIntoChunks(Uint8List data, int chunkSize) {
    final chunks = <Uint8List>[];
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  Uint8List _deriveHmacKey(Uint8List masterKey) {
    final hmacKeySeed = Uint8List.fromList(utf8.encode('VNC_HMAC_KEY'));
    return HMACSHA256.compute(hmacKeySeed, masterKey);
  }
}
