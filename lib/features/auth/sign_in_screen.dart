import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/developer_only_callout_card.dart';
import '../../theme/app_theme.dart';
import 'quick_sign_in_accounts.dart';

/// Signed-out screen: Clerk's prebuilt sign-in / sign-up UI, plus a
/// debug-only list of test accounts for one-tap sign-in.
///
/// Sign-in itself is observed by `AuthController` through Clerk's state, so
/// nothing here needs to hand a result back.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.infoMessage});

  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final accounts = quickSignInAccounts;

    return Scaffold(
      body: SafeArea(
        child: ClerkErrorListener(
          handler: _showClerkError,
          child: ListView(
            padding: AppTheme.screenPadding(),
            children: [
              if (infoMessage != null) ...[
                Text(
                  infoMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
              const ClerkAuthentication(),
              if (accounts.isNotEmpty) ...[
                const SizedBox(height: 16),
                _QuickSignInCard(accounts: accounts),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clerk's own handler shows each error for four seconds, which is too short
/// to read a password rule. This one stays until closed or replaced.
void _showClerkError(BuildContext context, clerk.ClerkError error) {
  // Server errors carry Clerk's full sentence; the rest describe themselves.
  final message = error.errors?.errorMessage ?? error.toString();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 30),
        showCloseIcon: true,
      ),
    );
}

class _QuickSignInCard extends StatefulWidget {
  const _QuickSignInCard({required this.accounts});

  final List<QuickSignInAccount> accounts;

  @override
  State<_QuickSignInCard> createState() => _QuickSignInCardState();
}

class _QuickSignInCardState extends State<_QuickSignInCard> {
  String? _signingInEmail;

  Future<void> _signIn(QuickSignInAccount account) async {
    final auth = ClerkAuth.of(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _signingInEmail = account.email);
    try {
      // Drop any half-finished sign-in/sign-up from the prebuilt form first.
      await auth.resetClient();
      await auth.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: account.email,
        password: account.password,
      );
      // Success is picked up by AuthController via Clerk's state.
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Quick sign-in failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _signingInEmail = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DeveloperOnlyCalloutCard(
      title: 'Test accounts',
      description: 'One-tap Clerk sign-in. Debug builds only.',
      actions: [
        for (final account in widget.accounts)
          OutlinedButton(
            onPressed: _signingInEmail == null ? () => _signIn(account) : null,
            child: Text(
              _signingInEmail == account.email ? 'Signing in…' : account.label,
            ),
          ),
      ],
    );
  }
}
