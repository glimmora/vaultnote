import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:vaultnote/core/crypto/secure_random.dart';
import 'package:vaultnote/core/crypto/key_manager.dart';
import 'package:vaultnote/core/storage/vnc_format.dart';
import 'package:vaultnote/domain/entities/note.dart';

void main() {
  group('VNCFormat', () {
    late KeyManager keyManager;
    late Uint8List masterKey;
    late Uint8List hmacKey;

    setUp(() async {
      keyManager = KeyManager();
      final salt = SecureRandom.bytes(32);
      await keyManager.unlock('test-password', salt, null);
      masterKey = keyManager.masterKey!;
      hmacKey = keyManager.hmacKey!;
    });

    tearDown(() {
      keyManager.dispose();
    });

    test('encryptNote and decryptNote should work correctly', () async {
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        body: 'This is a test note body',
        labels: ['work', 'important'],
        color: '#FFFFFF',
        created: DateTime.now(),
        modified: DateTime.now(),
        pinned: false,
        archived: false,
      );

      final encrypted = await VNCFormat.encryptNote(note, masterKey, hmacKey);
      final decrypted = await VNCFormat.decryptNote(encrypted, masterKey, hmacKey);

      expect(decrypted.id, equals(note.id));
      expect(decrypted.title, equals(note.title));
      expect(decrypted.body, equals(note.body));
      expect(decrypted.labels, equals(note.labels));
      expect(decrypted.color, equals(note.color));
      expect(decrypted.pinned, equals(note.pinned));
      expect(decrypted.archived, equals(note.archived));
    });

    test('encrypted data should have correct structure', () async {
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        body: 'This is a test note body',
        labels: [],
        color: '#FFFFFF',
        created: DateTime.now(),
        modified: DateTime.now(),
        pinned: false,
        archived: false,
      );

      final encrypted = await VNCFormat.encryptNote(note, masterKey, hmacKey);

      // Check minimum size
      final minSize = VNCFormat.headerSize +
          VNCFormat.kdfParamsSize +
          VNCFormat.saltSize +
          VNCFormat.ivSize +
          VNCFormat.authTagSize +
          VNCFormat.hmacSize;
      expect(encrypted.length, greaterThanOrEqualTo(minSize));

      // Check magic bytes
      for (int i = 0; i < 4; i++) {
        expect(encrypted[i], equals(VNCFormat.magic[i]));
      }
    });

    test('decryptNote with wrong key should throw', () async {
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        body: 'This is a test note body',
        labels: [],
        color: '#FFFFFF',
        created: DateTime.now(),
        modified: DateTime.now(),
        pinned: false,
        archived: false,
      );

      final encrypted = await VNCFormat.encryptNote(note, masterKey, hmacKey);
      final wrongKey = SecureRandom.bytes(32);

      expect(
        () => VNCFormat.decryptNote(encrypted, wrongKey, hmacKey),
        throwsException,
      );
    });

    test('decryptNote with tampered data should throw', () async {
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        body: 'This is a test note body',
        labels: [],
        color: '#FFFFFF',
        created: DateTime.now(),
        modified: DateTime.now(),
        pinned: false,
        archived: false,
      );

      final encrypted = await VNCFormat.encryptNote(note, masterKey, hmacKey);
      
      // Tamper with the data
      final tampered = Uint8List.fromList(encrypted);
      tampered[encrypted.length - 10] = 0xFF;

      expect(
        () => VNCFormat.decryptNote(tampered, masterKey, hmacKey),
        throwsException,
      );
    });

    test('extractSalt should return correct salt', () async {
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        body: 'This is a test note body',
        labels: [],
        color: '#FFFFFF',
        created: DateTime.now(),
        modified: DateTime.now(),
        pinned: false,
        archived: false,
      );

      final encrypted = await VNCFormat.encryptNote(note, masterKey, hmacKey);
      final salt = VNCFormat.extractSalt(encrypted);

      expect(salt.length, equals(VNCFormat.saltSize));
    });
  });
}