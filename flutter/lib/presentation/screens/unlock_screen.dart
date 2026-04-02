import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../cubits/crypto_cubit.dart';
import '../cubits/note_cubit.dart';
import '../cubits/label_cubit.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSetupMode = false;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword() {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
      });
      return false;
    }

    if (_isSetupMode) {
      if (password.length < 6) {
        setState(() {
          _passwordError = 'Password must be at least 6 characters';
        });
        return false;
      }

      if (_confirmPasswordController.text != password) {
        setState(() {
          _confirmPasswordError = 'Passwords do not match';
        });
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cryptoCubit = context.read<CryptoCubit>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),
                Text(
                  'VaultNote',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSetupMode
                      ? 'Set up your master password'
                      : 'Enter your password to unlock',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: _isSetupMode ? TextInputAction.next : TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
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
                    errorText: _passwordError,
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _handleSubmit(cryptoCubit),
                ),
                if (_isSetupMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _confirmPasswordError,
                    ),
                    onChanged: (_) {
                      if (_confirmPasswordError != null) {
                        setState(() {
                          _confirmPasswordError = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _handleSubmit(cryptoCubit),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => _handleSubmit(cryptoCubit),
                    icon: const Icon(Icons.lock_open),
                    label: Text(_isSetupMode ? 'Set Password' : 'Unlock'),
                  ),
                ),
                if (!_isSetupMode) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSetupMode = true;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('First time? Set up password'),
                  ),
                ],
                if (_isSetupMode) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSetupMode = false;
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to unlock'),
                  ),
                ],
                BlocListener<CryptoCubit, CryptoState>(
                  listener: (context, state) {
                    if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error!),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    if (state.isUnlocked) {
                      context.read<NoteCubit>().loadNotes();
                      context.read<LabelCubit>().loadLabels();
                    }
                  },
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit(CryptoCubit cryptoCubit) async {
    if (!_validatePassword()) return;

    if (_isSetupMode) {
      await cryptoCubit.setupNewPassword(_passwordController.text);
    } else {
      await cryptoCubit.unlockWithPassword(_passwordController.text);
    }
  }
}
