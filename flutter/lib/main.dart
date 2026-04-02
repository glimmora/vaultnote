import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/crypto/key_manager.dart';
import 'core/storage/secure_prefs.dart';
import 'core/storage/note_repository.dart';
import 'core/storage/label_repository.dart';
import 'core/export/vnc_exporter.dart';
import 'core/export/vnc_importer.dart';
import 'presentation/cubits/note_cubit.dart';
import 'presentation/cubits/label_cubit.dart';
import 'presentation/cubits/crypto_cubit.dart';
import 'presentation/screens/unlock_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  try {
    final keyManager = KeyManager();
    final securePrefs = SecurePrefs();
    final noteRepository = NoteRepository(keyManager);
    final labelRepository = LabelRepository(keyManager);
    final exporter = VNCExporter(keyManager);
    final importer = VNCImporter(keyManager);

    await noteRepository.init();
    await labelRepository.init();

    runApp(MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: keyManager),
        RepositoryProvider.value(value: securePrefs),
        RepositoryProvider.value(value: noteRepository),
        RepositoryProvider.value(value: labelRepository),
        RepositoryProvider.value(value: exporter),
        RepositoryProvider.value(value: importer),
      ],
      child: const VaultNoteApp(),
    ));
  } catch (e, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
