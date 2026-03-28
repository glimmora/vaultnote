import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:equatable/equatable.dart';
import '../crypto/argon2_kdf.dart';
import '../crypto/aes_gcm.dart';
import '../crypto/hmac_sha256.dart';
import '../../domain/entities/note.dart';

/// QR Code decoder session - assembles chunks and decrypts
class QRImportSession extends Equatable {
  final int total;
  final Map<int, Uint8List> chunks = {};
  Uint8List? _salt;
  Uint8List? _iv;
  Uint8List? _hmac;
  final int crc32;

  QRImportSession({
    required this.total,
    required this.crc32,
  });

  bool get isComplete => chunks.length == total;

  /// Add a chunk from scanned QR
  void addChunk(int index, Uint8List data) {
    chunks[index] = data;

    // Extract salt and IV from first chunk (index 0)
    if (index == 0 && data.length >= 44) {
      _salt = data.sublist(0, 32);
      _iv = data.sublist(32, 44);
    }

    // Extract HMAC from last chunk
    if (index == total - 1) {
      _hmac = data.sublist(data.length - 32);
    }
  }

  /// Assemble and decrypt the note
  Future<Note> assemble(String password) async {
    if (!isComplete) {
      throw StateError('Not all chunks received');
    }

    if (_salt == null || _iv == null || _hmac == null) {
      throw StateError('Missing salt, IV, or HMAC');
    }

    // Combine all chunks
    final combined = Uint8List.fromList([
      for (var i = 0; i < total; i++) ...chunks[i]!,
    ]);

    // Extract components
    final salt = combined.sublist(0, 32);
    final iv = combined.sublist(32, 44);
    final hmacStart = 44 + (combined.length - 32 - 44);
    final ciphertext = combined.sublist(44, combined.length - 32 - 16);
    final authTag = combined.sublist(combined.length - 32 - 16, combined.length - 32);
    final storedHmac = combined.sublist(combined.length - 32);

    // Verify HMAC
    final dataToHmac = Uint8List.fromList([
      ...salt,
      ...iv,
      ...ciphertext,
      ...authTag,
    ]);
    final hmacKey = _deriveHmacKeyFromPassword(password, salt);
    if (!HMACSHA256.verify(dataToHmac, hmacKey, storedHmac)) {
      throw Exception('HMAC verification failed - QR may be tampered');
    }

    // Derive key and decrypt
    final kdf = Argon2KDF();
    final key = await kdf.deriveKey(password, salt);

    final decrypted = AESGCM.decrypt(ciphertext, key, iv, authTag);

    // Decompress
    final decompressed = GZipDecoder().decodeBytes(decrypted);
    final jsonString = utf8.decode(decompressed);

    // Parse JSON
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    return Note.fromJson(jsonData);
  }

  Uint8List _deriveHmacKeyFromPassword(String password, Uint8List salt) async {
    final kdf = Argon2KDF();
    final key = await kdf.deriveKey(password, salt);
    final hmacKeySeed = Uint8List.fromList(utf8.encode('VNC_HMAC_KEY'));
    return HMACSHA256.compute(hmacKeySeed, key);
  }

  @override
  List<Object?> get props => [total, crc32, chunks.length];
}

/// Parse QR string and extract header info
/// Returns (version, index, total, crc32, payload)
(String version, int index, int total, int crc32, Uint8List payload)? parseQRString(String qrData) {
  try {
    // Format: "VNQ:v1:{index}/{total}:{crc32}:{base64payload}"
    // or "VNQ:v1:{index}/{total}:{base64payload}" (crc32 optional)
    final parts = qrData.split(':');
    if (parts.length < 4) return null;

    if (parts[0] != 'VNQ') return null;

    final version = parts[1];
    final indexTotal = parts[2].split('/');
    if (indexTotal.length != 2) return null;

    final index = int.parse(indexTotal[0]) - 1; // 0-based
    final total = int.parse(indexTotal[1]);

    // Check if crc32 is present
    int crc32 = 0;
    String payloadStr;
    
    if (parts.length == 5) {
      crc32 = int.parse(parts[3]);
      payloadStr = parts[4];
    } else {
      payloadStr = parts[3];
    }

    final payload = base64Url.decode(payloadStr);

    return (version, index, total, crc32, payload);
  } catch (e) {
    return null;
  }
}
