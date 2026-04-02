import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../cubits/crypto_cubit.dart';
import '../cubits/note_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Import & Export'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text('Import via QR'),
                  subtitle: const Text('Scan QR codes to import notes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/qr-import');
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  minTileHeight: 56,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Import from File'),
                  subtitle: const Text('Import .vnc container file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importFromFile(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Export All Notes'),
                  subtitle: const Text('Backup all notes to .vnc file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportAllNotes(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Security'),
          Card(
            child: Column(
              children: [
                BlocBuilder<CryptoCubit, CryptoState>(
                  builder: (context, state) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Biometric Unlock'),
                      subtitle: const Text('Use fingerprint or face to unlock'),
                      value: false,
                      onChanged: (value) {},
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Auto-Lock'),
                  subtitle: const Text('Lock after period of inactivity'),
                  trailing: const Text('5 min'),
                  onTap: () => _showAutoLockDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your master password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changePassword(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_open, color: Colors.red),
                  title: const Text(
                    'Lock Now',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Require password to access'),
                  onTap: () {
                    context.read<CryptoCubit>().lock();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Appearance'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme toggle coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Encryption'),
                  subtitle: const Text('AES-256-GCM + Argon2id'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 8),
                Text(
                  'VaultNote',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
                Text(
                  'Your notes, securely encrypted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
      ),
    );
  }

  void _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['vnc'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to read file'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final notes = await context.read<CryptoCubit>().importFile(bytes);

      if (context.mounted) {
        if (notes.isNotEmpty) {
          await context.read<NoteCubit>().loadNotes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported ${notes.length} note(s)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No notes found in file'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _exportAllNotes(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export all notes coming soon')),
    );
  }

  void _showAutoLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Lock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('1 minute'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('5 minutes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('10 minutes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Never'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password coming soon')),
    );
  }
}
