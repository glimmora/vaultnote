import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/crypto_cubit.dart';

/// Settings preview widget for the home screen settings tab
class SettingsPreview extends StatelessWidget {
  const SettingsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // App info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.indigo),
                const SizedBox(height: 8),
                const Text(
                  'VaultNote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick settings
        const Text(
          'Quick Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Encryption'),
                subtitle: const Text('AES-256-GCM with Argon2id'),
                enabled: false,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Storage'),
                subtitle: const Text('Offline-first, local only'),
                enabled: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Import from QR'),
                onTap: () {
                  Navigator.pushNamed(context, '/qr-import');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Import from File'),
                onTap: () {
                  context.read<CryptoCubit>().promptImportFile();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Full Settings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Security info
        Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.indigo.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Security Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• All notes are encrypted locally\n'
                  '• No data is sent to servers\n'
                  '• Password is never stored\n'
                  '• Use QR or file export for backup',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
