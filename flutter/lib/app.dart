import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/crypto/key_manager.dart';
import 'core/storage/secure_prefs.dart';
import 'core/storage/note_repository.dart';
import 'core/storage/label_repository.dart';
import 'core/export/vnc_importer.dart';
import 'domain/entities/note.dart';
import 'presentation/cubits/note_cubit.dart';
import 'presentation/cubits/label_cubit.dart';
import 'presentation/cubits/crypto_cubit.dart';
import 'presentation/screens/unlock_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/note_editor.dart';
import 'presentation/screens/label_screen.dart';
import 'presentation/screens/qr_export_screen.dart';
import 'presentation/screens/qr_import_screen.dart';
import 'presentation/screens/settings_screen.dart';

class VaultNoteApp extends StatelessWidget {
  const VaultNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CryptoCubit>(
          create: (context) => CryptoCubit(
            context.read<KeyManager>(),
            context.read<SecurePrefs>(),
            context.read<VNCImporter>(),
          )..initialize(),
        ),
        BlocProvider<NoteCubit>(
          create: (context) => NoteCubit(
            context.read<NoteRepository>(),
            context.read<LabelRepository>(),
          ),
        ),
        BlocProvider<LabelCubit>(
          create: (context) => LabelCubit(
            context.read<LabelRepository>(),
            context.read<NoteRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'VaultNote',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 2,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: BlocBuilder<CryptoCubit, CryptoState>(
          builder: (context, state) {
            if (!state.isInitialized) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!state.isUnlocked) {
              return const UnlockScreen();
            }
            return const HomeScreen();
          },
        ),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/note/new':
              return MaterialPageRoute(
                builder: (_) => const NoteEditorScreen(),
              );
            case '/note/edit':
              final note = settings.arguments is Note ? settings.arguments as Note : null;
              if (note == null) return null;
              return MaterialPageRoute(
                builder: (_) => NoteEditorScreen(note: note),
              );
            case '/labels':
              return MaterialPageRoute(
                builder: (_) => const LabelScreen(),
              );
            case '/qr-export':
              final qrNote = settings.arguments is Note ? settings.arguments as Note : null;
              if (qrNote == null) return null;
              return MaterialPageRoute(
                builder: (_) => QRExportScreen(note: qrNote),
              );
            case '/qr-import':
              return MaterialPageRoute(
                builder: (_) => const QRImportScreen(),
              );
            case '/settings':
              return MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
