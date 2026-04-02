import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../cubits/crypto_cubit.dart';
import '../../domain/entities/note.dart';

class QRExportScreen extends StatefulWidget {
  final Note note;

  const QRExportScreen({super.key, required this.note});

  @override
  State<QRExportScreen> createState() => _QRExportScreenState();
}

class _QRExportScreenState extends State<QRExportScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _hasPassword = false;
  bool _isGenerating = false;
  int _currentQrIndex = 0;
  int _currentQrIndex = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export as QR'),
      ),
      body: BlocConsumer<CryptoCubit, CryptoState>(
        listener: (context, state) {
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
          if (state.qrChunks.isEmpty || !_hasPassword) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code,
                    size: 80,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Export "${widget.note.title}"',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set a password to encrypt the QR code',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter a password for encryption',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateQR,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code),
                      label: const Text('Generate QR'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The recipient will need this password to decrypt the note',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Show QR code
          final currentIndex = _currentQrIndex;
          final totalChunks = state.qrChunks.length;
          if (currentIndex >= totalChunks) {
            _currentQrIndex = totalChunks - 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  widget.note.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'QR ${currentIndex + 1} of $totalChunks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 24),
                QrImageView(
                  data: state.qrChunks[currentIndex < state.qrChunks.length ? currentIndex : 0],
                  version: QrVersions.auto,
                  size: 280.0,
                  backgroundColor: Colors.white,
                  embeddedImageStyle: null,
                ),
                const SizedBox(height: 32),
                // Carousel dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalChunks,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == currentIndex
                            ? Colors.indigo
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (currentIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentQrIndex = currentIndex - 1;
                            });
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                      ),
                    if (currentIndex > 0) const SizedBox(width: 16),
                    if (currentIndex < totalChunks - 1)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentQrIndex = currentIndex + 1;
                            });
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ),
                      ),
                    if (currentIndex > 0) const SizedBox(width: 16),
                    if (currentIndex < totalChunks - 1)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentQrIndex = currentIndex + 1;
                            });
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ),
                    if (currentIndex < totalChunks - 1) const SizedBox(width: 16),
                    if (currentIndex == totalChunks - 1)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            _shareQR();
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<CryptoCubit>().resetQRImport();
                    setState(() {
                      _hasPassword = false;
                      _passwordController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate New QR'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _generateQR() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    await context.read<CryptoCubit>().exportToQR(
          widget.note,
          _passwordController.text,
        );

    setState(() {
      _isGenerating = false;
      _hasPassword = true;
    });
  }

  void _shareQR() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }
}
