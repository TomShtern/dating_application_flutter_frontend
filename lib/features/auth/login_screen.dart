import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../theme/app_theme.dart';
import 'auth_controller.dart';
import 'dev_user_picker_screen.dart';
import 'signup_screen.dart';

/// Phone-alpha login screen. Email + password only.
///
/// Intentionally minimal — design polish is out of scope for this pass.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.infoMessage});

  final String? infoMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on ApiError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error, stackTrace) {
      debugPrint('Login failed: $error\n$stackTrace');
      if (mounted) {
        setState(() => _errorMessage = 'Login failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppTheme.screenPadding(),
            children: [
              const SizedBox(height: 24),
              Text(
                'Sign in',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your email and password to continue.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (widget.infoMessage != null) ...[
                const SizedBox(height: 12),
                _InfoBanner(message: widget.infoMessage!),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Email is required.';
                  if (!v.contains('@')) return 'Enter a valid email address.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignupScreen(),
                        ),
                      ),
                child: const Text('Create an account'),
              ),
              if (kDebugMode) ...[
                const Divider(height: 32),
                TextButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DevUserPickerScreen(),
                          ),
                        ),
                  icon: const Icon(Icons.developer_mode_rounded),
                  label: const Text('Dev: pick a seeded user'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }
}
