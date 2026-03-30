import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../domain/entities/note.dart';
import '../cubits/crypto_cubit.dart';
import '../cubits/note_cubit.dart';

class QRImportScreen extends StatefulWidget {
  const QRImportScreen({super.key});

  @override
  State<QRImportScreen> createState() => _QRImportScreenState();
}

class _QRImportScreenState extends State<QRImportScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isPasswordVisible = false;
  final _passwordController = TextEditingController();
  bool _showPasswordDialog = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import via QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(),
          ),
        ],
      ),
      body: BlocConsumer<CryptoCubit, CryptoState>(
        listener: (context, state) {
          if (state.importedNote != null) {
            _showImportSuccess(state.importedNote!);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final session = state.qrSession;

          return Column(
            children: [
              // Progress indicator
              if (session != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: session.chunks.length / session.total,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation(Colors.indigo),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scanned ${session.chunks.length} of ${session.total} QR codes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (session.isComplete) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showPasswordInputDialog(),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Enter Password to Decrypt'),
                        ),
                      ],
                    ],
                  ),
                ),
              // Camera view
              Expanded(
                flex: 2,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.indigo,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 4,
                    cutOutSize: 280,
                  ),
                ),
              ),
              // Scanned chunks list
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned QR Codes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: session == null || session.chunks.isEmpty
                            ? Center(
                                child: Text(
                                  'Scan QR codes to import a note',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  session.total,
                                  (index) {
                                    final isScanned = session.chunks.containsKey(index);
                                    return Chip(
                                      avatar: Icon(
                                        isScanned
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        size: 18,
                                        color: isScanned ? Colors.green : Colors.grey,
                                      ),
                                      label: Text('${index + 1}'),
                                      backgroundColor: isScanned
                                          ? Colors.green.shade50
                                          : Colors.grey.shade200,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      // Process scanned QR
      context.read<CryptoCubit>().processScannedQR(scanData.code ?? '');
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Import'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Ask the sender to export their note as QR code'),
            const SizedBox(height: 8),
            const Text('2. Point your camera at each QR code in order'),
            const SizedBox(height: 8),
            const Text('3. The app will automatically detect and scan each QR'),
            const SizedBox(height: 8),
            const Text('4. After all QRs are scanned, enter the password to decrypt'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPasswordInputDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter the password set by sender',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          autofocus: true,
          onSubmitted: (_) => _decryptNote(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _passwordController.clear();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _decryptNote,
            child: const Text('Decrypt'),
          ),
        ],
      ),
    );
  }

  void _decryptNote() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    Navigator.pop(context);
    
    final success = await context.read<CryptoCubit>().executeQRImport(
          _passwordController.text,
        );

    if (success) {
      _passwordController.clear();
    }
  }

  void _showImportSuccess(Object? note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Note "${(note as Note).title}" has been imported successfully!'),
            const SizedBox(height: 16),
            Text(
              'You can now find it in your notes list.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              context.read<NoteCubit>().loadNotes();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
