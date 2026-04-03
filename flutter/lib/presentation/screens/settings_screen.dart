import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../cubits/crypto_cubit.dart';
import '../cubits/note_cubit.dart';
import '../../core/storage/secure_prefs.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/export/vnc_exporter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _autoLockMinutes = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final securePrefs = context.read<SecurePrefs>();
    final autoLockMinutes = await securePrefs.getAutoLockMinutes();
    setState(() {
      _autoLockMinutes = autoLockMinutes;
    });
  }

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
                      const SnackBar(
                        content: Text('Theme follows system setting'),
                        behavior: SnackBarBehavior.floating,
                      ),
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
    try {
      final notes = await context.read<NoteCubit>().state.notes;
      if (notes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No notes to export'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final exporter = context.read<VNCExporter>();
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(appDir.path, 'vaultnote_backup_$timestamp.vnc');

      final file = await exporter.exportMultipleNotes(notes, outputPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${notes.length} notes to ${file.path}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              trailing: _autoLockMinutes == 1 ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () async {
                await _saveAutoLockMinutes(1);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('5 minutes'),
              trailing: _autoLockMinutes == 5 ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () async {
                await _saveAutoLockMinutes(5);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('10 minutes'),
              trailing: _autoLockMinutes == 10 ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () async {
                await _saveAutoLockMinutes(10);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Never'),
              trailing: _autoLockMinutes == 0 ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () async {
                await _saveAutoLockMinutes(0);
                if (context.mounted) Navigator.pop(context);
              },
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

  Future<void> _saveAutoLockMinutes(int minutes) async {
    final securePrefs = context.read<SecurePrefs>();
    final keyManager = context.read<KeyManager>();
    await securePrefs.setAutoLockMinutes(minutes);
    keyManager.setAutoLockTimeout(minutes * 60 * 1000);
    setState(() {
      _autoLockMinutes = minutes;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-lock set to ${minutes == 0 ? 'Never' : '$minutes minute(s)'}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentController.text.isEmpty || _newController.text.isEmpty || _confirmController.text.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    if (_newController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cryptoCubit = context.read<CryptoCubit>();
      final success = await cryptoCubit.changePassword(_currentController.text, _newController.text);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() {
            _error = 'Current password is incorrect';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to change password: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            TextField(
              controller: _currentController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_loading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_loading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _changePassword,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Change'),
        ),
      ],
    );
  }
}
