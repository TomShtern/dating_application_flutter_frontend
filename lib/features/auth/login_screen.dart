import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../theme/app_theme.dart';
import 'auth_controller.dart';
import 'dev_user_picker_screen.dart';
import 'signup_screen.dart';

const _loginRose = Color(0xFFD95F84);
const _loginViolet = Color(0xFF8E6DE8);
const _loginPeach = Color(0xFFFFD7C2);
const _loginSky = Color(0xFFB7DCF8);
const _loginMint = Color(0xFFBDE7D2);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const _LoginPastelBackdrop(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: AppTheme.screenPadding(),
                children: [
                  const SizedBox(height: 8),
                  const _LoginIdentityPanel(),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: AppTheme.surfaceDecoration(
                      context,
                      color: Color.alphaBlend(
                        _loginRose.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.12
                              : 0.04,
                        ),
                        colorScheme.surfaceContainerLow,
                      ),
                      prominent: true,
                    ),
                    child: Padding(
                      padding: AppTheme.sectionPadding(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Step back into your chats, matches, and profile updates.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (widget.infoMessage != null) ...[
                            const SizedBox(height: 12),
                            _InfoBanner(message: widget.infoMessage!),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Email is required.';
                              if (!v.contains('@')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                            ),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _loginRose,
                                foregroundColor: Colors.white,
                              ),
                              child: _submitting
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SignupScreen(
                                          initialEmail: _emailController.text
                                              .trim(),
                                          passwordRetriever: () =>
                                              _passwordController.text,
                                        ),
                                      ),
                                    ),
                              child: const Text('Create an account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 14),
                    DeveloperOnlyCalloutCard(
                      title: 'Developer shortcut',
                      description:
                          'Use the seeded picker when you need fast local flow checks.',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const DevUserPickerScreen(),
                                  ),
                                ),
                          icon: const Icon(Icons.developer_mode_rounded),
                          label: const Text('Pick a seeded user'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPastelBackdrop extends StatelessWidget {
  const _LoginPastelBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  (isDark ? _loginViolet : _loginPeach).withValues(
                    alpha: isDark ? 0.10 : 0.18,
                  ),
                  surface,
                ),
                Color.alphaBlend(
                  (isDark ? _loginSky : _loginMint).withValues(
                    alpha: isDark ? 0.06 : 0.10,
                  ),
                  surface,
                ),
                surface,
              ],
            ),
          ),
        ),
        Positioned(
          top: -18,
          right: -8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (isDark ? _loginViolet : _loginRose).withValues(
                  alpha: isDark ? 0.10 : 0.08,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(80)),
              ),
              child: const SizedBox(width: 220, height: 180),
            ),
          ),
        ),
        Positioned(
          left: -24,
          bottom: 112,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (isDark ? _loginSky : _loginViolet).withValues(
                  alpha: isDark ? 0.08 : 0.06,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(72)),
              ),
              child: const SizedBox(width: 188, height: 116),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginIdentityPanel extends StatelessWidget {
  const _LoginIdentityPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _loginSky.withValues(alpha: isDark ? 0.10 : 0.05),
          theme.colorScheme.surface.withValues(alpha: isDark ? 0.74 : 0.94),
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _loginRose.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.favorite_rounded,
                  color: _loginRose,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chats, matches, and your next maybe-yes are waiting when you are.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _LoginIdentityChip(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chats waiting',
                        color: _loginSky,
                      ),
                      _LoginIdentityChip(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Matches nearby',
                        color: _loginRose,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginIdentityChip extends StatelessWidget {
  const _LoginIdentityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
