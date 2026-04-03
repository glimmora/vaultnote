import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/crypto/argon2_kdf.dart';
import '../../core/storage/secure_prefs.dart';
import '../../core/qr/qr_encoder.dart';
import '../../core/qr/qr_decoder.dart';
import '../../core/export/vnc_importer.dart';
import '../../domain/entities/note.dart';

// Events
abstract class CryptoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeCryptoEvent extends CryptoEvent {}
class UnlockWithPasswordEvent extends CryptoEvent {
  final String password;
  UnlockWithPasswordEvent(this.password);
  @override
  List<Object?> get props => [password];
}
class SetupNewPasswordEvent extends CryptoEvent {
  final String password;
  SetupNewPasswordEvent(this.password);
  @override
  List<Object?> get props => [password];
}
class LockEvent extends CryptoEvent {}
class ExportQREvent extends CryptoEvent {
  final Note note;
  final String password;
  ExportQREvent(this.note, this.password);
  @override
  List<Object?> get props => [note, password];
}
class ImportQREvent extends CryptoEvent {
  final String qrData;
  ImportQREvent(this.qrData);
  @override
  List<Object?> get props => [qrData];
}
class ImportQRExecuteEvent extends CryptoEvent {
  final String password;
  ImportQRExecuteEvent(this.password);
  @override
  List<Object?> get props => [password];
}
class ImportFileEvent extends CryptoEvent {
  final Uint8List data;
  ImportFileEvent(this.data);
  @override
  List<Object?> get props => [data];
}

// State
class CryptoState extends Equatable {
  final bool isInitialized;
  final bool isUnlocked;
  final bool needsSetup;
  final String? error;
  final List<String> qrChunks;
  final int qrIndex;
  final QRImportSession? qrSession;
  final Note? importedNote;

  const CryptoState({
    this.isInitialized = false,
    this.isUnlocked = false,
    this.needsSetup = false,
    this.error,
    this.qrChunks = const [],
    this.qrIndex = 0,
    this.qrSession,
    this.importedNote,
  });

  CryptoState copyWith({
    bool? isInitialized,
    bool? isUnlocked,
    bool? needsSetup,
    String? error,
    List<String>? qrChunks,
    int? qrIndex,
    QRImportSession? qrSession,
    Note? importedNote,
  }) {
    return CryptoState(
      isInitialized: isInitialized ?? this.isInitialized,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      needsSetup: needsSetup ?? this.needsSetup,
      error: error ?? this.error,
      qrChunks: qrChunks ?? this.qrChunks,
      qrIndex: qrIndex ?? this.qrIndex,
      qrSession: qrSession ?? this.qrSession,
      importedNote: importedNote ?? this.importedNote,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        isUnlocked,
        needsSetup,
        error,
        qrChunks.length,
        qrIndex,
        qrSession,
        importedNote,
      ];
}

// Cubit
class CryptoCubit extends Cubit<CryptoState> {
  final KeyManager _keyManager;
  final SecurePrefs _securePrefs;
  final VNCImporter? _importer;
  final Argon2KDF _kdf = Argon2KDF();

  CryptoCubit(
    this._keyManager,
    this._securePrefs,
    this._importer,
  ) : super(const CryptoState());

  Future<void> initialize() async {
    try {
      final salt = await _securePrefs.getSalt();
      
      if (salt == null) {
        emit(state.copyWith(needsSetup: true, isInitialized: true));
      } else {
        emit(state.copyWith(
          isInitialized: true,
          needsSetup: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<bool> setupNewPassword(String password) async {
    try {
      final salt = _kdf.generateSalt();
      
      // Store salt
      await _securePrefs.setSalt(salt);
      
      // Create and store verification hash
      await _keyManager.unlock(password, salt, null);
      final verifyHash = _keyManager.createVerifyHash();
      await _securePrefs.setVerifyHash(verifyHash);
      
      emit(state.copyWith(
        isInitialized: true,
        needsSetup: false,
        isUnlocked: true,
      ));
      
      return true;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return false;
    }
  }

  Future<bool> unlockWithPassword(String password) async {
    try {
      final salt = await _securePrefs.getSalt();
      if (salt == null) {
        emit(state.copyWith(error: 'No password set up'));
        return false;
      }

      final verifyHash = await _securePrefs.getVerifyHash();
      final success = await _keyManager.unlock(password, salt, verifyHash);
      
      if (success) {
        emit(state.copyWith(isUnlocked: true, error: null));
        return true;
      } else {
        emit(state.copyWith(error: 'Incorrect password'));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return false;
    }
  }

  void lock() {
    _keyManager.lock();
    emit(state.copyWith(isUnlocked: false));
  }

  Future<void> exportToQR(Note note, String password) async {
    try {
      final encoder = QREncoder();
      final chunks = await encoder.exportNoteAsQR(note, password);
      emit(state.copyWith(
        qrChunks: chunks,
        qrIndex: 0,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void processScannedQR(String qrData) {
    try {
      final parsed = parseQRString(qrData);
      if (parsed == null) {
        emit(state.copyWith(error: 'Invalid QR format'));
        return;
      }

      final (version, index, total, crc32, payload) = parsed;
      
      QRImportSession session;
      if (state.qrSession == null) {
        session = QRImportSession(total: total, crc32: crc32);
      } else {
        session = state.qrSession!;
      }

      session.addChunk(index, payload);
      
      emit(state.copyWith(
        qrSession: session,
        qrIndex: index + 1,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<bool> executeQRImport(String password) async {
    try {
      final session = state.qrSession;
      if (session == null || !session.isComplete) {
        emit(state.copyWith(error: 'QR scan incomplete'));
        return false;
      }

      final note = await session.assemble(password);
      emit(state.copyWith(
        importedNote: note,
        error: null,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return false;
    }
  }

  void resetQRImport() {
    emit(state.copyWith(
      qrSession: null,
      qrIndex: 0,
      importedNote: null,
      qrChunks: [],
    ));
  }

  Future<List<Note>> importFile(Uint8List data) async {
    try {
      if (_importer == null) {
        throw StateError('Importer not initialized');
      }
      final notes = await _importer!.importContainer(data);
      return notes;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return [];
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  /// Change password - re-encrypt all notes with new password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (newPassword.length < 6) {
        emit(state.copyWith(error: 'New password must be at least 6 characters'));
        return false;
      }

      // Verify current password
      final salt = await _securePrefs.getSalt();
      if (salt == null) {
        emit(state.copyWith(error: 'No password set up'));
        return false;
      }

      final verifyHash = await _securePrefs.getVerifyHash();
      final currentSuccess = await _keyManager.unlock(currentPassword, salt, verifyHash);
      if (!currentSuccess) {
        emit(state.copyWith(error: 'Current password is incorrect'));
        return false;
      }

      // Generate new salt and key
      final newSalt = _kdf.generateSalt();
      await _keyManager.unlock(newPassword, newSalt, null);
      final newVerifyHash = _keyManager.createVerifyHash();

      // Store new credentials
      await _securePrefs.setSalt(newSalt);
      await _securePrefs.setVerifyHash(newVerifyHash);

      emit(state.copyWith(error: null));
      return true;
    } catch (e) {
      emit(state.copyWith(error: 'Failed to change password: $e'));
      return false;
    }
  }

  /// Prompt user to import a file
  void promptImportFile() {
    // This is handled by the settings screen directly
    emit(state.copyWith(error: null));
  }
}
