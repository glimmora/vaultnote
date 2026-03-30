import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import '../crypto/argon2_kdf.dart';
import '../crypto/aes_gcm.dart';
import '../crypto/hmac_sha256.dart';
import '../crypto/secure_random.dart';
import '../../domain/entities/note.dart';

/// .vnc file format parser and writer
/// 
/// Format:
/// [HEADER — 128 bytes]
///   Bytes 0–3   : Magic "VNC\x01"
///   Bytes 4–5   : Version (little-endian uint16)
///   Bytes 6–9   : Flags (bit 0=compressed, bit 1=has_label, bit 2=container)
///   Bytes 10–127: Reserved (padding)
/// 
/// [KDF PARAMS — 16 bytes]
///   Bytes 0–3   : Argon2id m_cost (uint32)
///   Bytes 4–7   : Argon2id t_cost (uint32)
///   Bytes 8–11  : Argon2id p_cost (uint32)
///   Bytes 12–15 : Reserved
/// 
/// [SALT — 32 bytes]
/// [IV/NONCE — 12 bytes]
/// [CIPHERTEXT — variable]
/// [GCM AUTH TAG — 16 bytes]
/// [HMAC-SHA256 — 32 bytes]
class VNCFormat {
  static const List<int> magic = [0x56, 0x4E, 0x43, 0x01]; // "VNC\x01"
  static const int version = 1;
  static const int headerSize = 128;
  static const int kdfParamsSize = 16;
  static const int saltSize = 32;
  static const int ivSize = 12;
  static const int authTagSize = 16;
  static const int hmacSize = 32;

  static const int flagCompressed = 1;
  static const int flagHasLabel = 2;
  static const int flagContainer = 4;

  /// Encrypt and serialize a note to .vnc format
  static Future<Uint8List> encryptNote(Note note, Uint8List key, Uint8List hmacKey) async {
    // Create payload
    final payload = note.toJson();
    final jsonString = jsonEncode(payload);
    
    // Compress
    final compressed = GZipEncoder().encode(Uint8List.fromList(utf8.encode(jsonString)));
    if (compressed == null) {
      throw Exception('Compression failed');
    }

    // Generate fresh salt and IV per save
    final salt = SecureRandom.bytes(saltSize);
    final iv = SecureRandom.bytes(ivSize);

    // Encrypt
    final (ciphertext, _, authTag) = AESGCM.encrypt(
      Uint8List.fromList(compressed),
      key,
      iv: iv,
    );

    // Build file without HMAC
    final fileWithoutHmac = _buildFile(
      salt,
      iv,
      ciphertext,
      authTag,
      flagCompressed | flagHasLabel,
    );

    // Compute HMAC over entire file
    final hmac = HMACSHA256.compute(fileWithoutHmac, hmacKey);

    // Combine everything
    final result = Uint8List(fileWithoutHmac.length + hmacSize);
    result.setAll(0, fileWithoutHmac);
    result.setAll(fileWithoutHmac.length, hmac);

    return result;
  }

  /// Decrypt and parse a note from .vnc format
  static Future<Note> decryptNote(Uint8List data, Uint8List key, Uint8List hmacKey) async {
    if (data.length < headerSize + kdfParamsSize + saltSize + ivSize + authTagSize + hmacSize) {
      throw Exception('Invalid .vnc file: too short');
    }

    // Verify magic
    for (int i = 0; i < 4; i++) {
      if (data[i] != magic[i]) {
        throw Exception('Invalid .vnc file: bad magic');
      }
    }

    // Extract HMAC (last 32 bytes)
    final storedHmac = data.sublist(data.length - hmacSize);
    final dataWithoutHmac = data.sublist(0, data.length - hmacSize);

    // Verify HMAC
    if (!HMACSHA256.verify(dataWithoutHmac, hmacKey, storedHmac)) {
      throw Exception('Invalid .vnc file: HMAC verification failed - file may be tampered');
    }

    // Extract salt and IV
    final salt = data.sublist(headerSize + kdfParamsSize, headerSize + kdfParamsSize + saltSize);
    final iv = data.sublist(headerSize + kdfParamsSize + saltSize, headerSize + kdfParamsSize + saltSize + ivSize);

    // Extract ciphertext and auth tag
    final ciphertextStart = headerSize + kdfParamsSize + saltSize + ivSize;
    final ciphertextEnd = data.length - hmacSize - authTagSize;
    final ciphertext = data.sublist(ciphertextStart, ciphertextEnd);
    final authTag = data.sublist(ciphertextEnd, data.length - hmacSize);

    // Decrypt
    final decrypted = AESGCM.decrypt(ciphertext, key, iv, authTag);

    // Decompress
    final decompressed = GZipDecoder().decodeBytes(decrypted);
    final jsonString = utf8.decode(decompressed);

    // Parse JSON
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Note.fromJson(json);
  }

  /// Build file structure without HMAC
  static Uint8List _buildFile(
    Uint8List salt,
    Uint8List iv,
    Uint8List ciphertext,
    Uint8List authTag,
    int flags,
  ) {
    final totalSize = headerSize + kdfParamsSize + saltSize + ivSize + ciphertext.length + authTagSize;
    final result = Uint8List(totalSize);
    var offset = 0;

    // Header (128 bytes)
    // Magic
    for (int i = 0; i < 4; i++) {
      result[offset++] = magic[i];
    }
    // Version (uint16 LE)
    result[offset++] = version & 0xFF;
    result[offset++] = (version >> 8) & 0xFF;
    // Flags (uint32 LE)
    result[offset++] = flags & 0xFF;
    result[offset++] = (flags >> 8) & 0xFF;
    result[offset++] = (flags >> 16) & 0xFF;
    result[offset++] = (flags >> 24) & 0xFF;
    // Reserved (bytes 10-127)
    offset = headerSize;

    // KDF Params (16 bytes)
    // m_cost (uint32 LE)
    final mCost = Argon2KDF.memoryCost;
    result[offset++] = mCost & 0xFF;
    result[offset++] = (mCost >> 8) & 0xFF;
    result[offset++] = (mCost >> 16) & 0xFF;
    result[offset++] = (mCost >> 24) & 0xFF;
    // t_cost (uint32 LE)
    final tCost = Argon2KDF.timeCost;
    result[offset++] = tCost & 0xFF;
    result[offset++] = (tCost >> 8) & 0xFF;
    result[offset++] = (tCost >> 16) & 0xFF;
    result[offset++] = (tCost >> 24) & 0xFF;
    // p_cost (uint32 LE)
    final pCost = Argon2KDF.parallelism;
    result[offset++] = pCost & 0xFF;
    result[offset++] = (pCost >> 8) & 0xFF;
    result[offset++] = (pCost >> 16) & 0xFF;
    result[offset++] = (pCost >> 24) & 0xFF;
    // Reserved (4 bytes)
    offset += 4;

    // Salt (32 bytes)
    result.setAll(offset, salt);
    offset += saltSize;

    // IV (12 bytes)
    result.setAll(offset, iv);
    offset += ivSize;

    // Ciphertext
    result.setAll(offset, ciphertext);
    offset += ciphertext.length;

    // Auth Tag (16 bytes)
    result.setAll(offset, authTag);

    return result;
  }

  /// Parse KDF params from file
  static (int mCost, int tCost, int pCost) parseKDFParams(Uint8List data) {
    final offset = headerSize;
    
    // m_cost
    int mCost = data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
    
    // t_cost
    int tCost = data[offset + 4] |
        (data[offset + 5] << 8) |
        (data[offset + 6] << 16) |
        (data[offset + 7] << 24);
    
    // p_cost
    int pCost = data[offset + 8] |
        (data[offset + 9] << 8) |
        (data[offset + 10] << 16) |
        (data[offset + 11] << 24);
    
    return (mCost, tCost, pCost);
  }

  /// Extract salt from .vnc file
  static Uint8List extractSalt(Uint8List data) {
    return data.sublist(headerSize + kdfParamsSize, headerSize + kdfParamsSize + saltSize);
  }
}
