import 'package:flutter/foundation.dart';

import '../../app/env.dart';

/// A Clerk dev-instance test account offered on the sign-in screen.
class QuickSignInAccount {
  const QuickSignInAccount({
    required this.label,
    required this.email,
    required this.password,
  });

  final String label;
  final String email;
  final String password;
}

/// Parses `label|email|password` entries separated by `;`. Malformed entries
/// are skipped. Passwords therefore cannot contain `;` or `|`.
List<QuickSignInAccount> parseQuickSignInAccounts(String raw) {
  final accounts = <QuickSignInAccount>[];
  for (final entry in raw.split(';')) {
    final parts = entry.split('|').map((part) => part.trim()).toList();
    if (parts.length != 3 || parts.any((part) => part.isEmpty)) continue;
    accounts.add(
      QuickSignInAccount(label: parts[0], email: parts[1], password: parts[2]),
    );
  }
  return accounts;
}

/// Quick sign-in accounts for this build. Always empty outside debug builds,
/// so release builds never offer a credential shortcut.
List<QuickSignInAccount> get quickSignInAccounts {
  if (!kDebugMode) return const [];
  return parseQuickSignInAccounts(Env.clerkTestAccounts);
}
