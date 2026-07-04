/// Lightweight client-side form validators.
///
/// These only guard against obvious typos before a request is sent — the
/// backend remains the source of truth for real validation.
library;

final RegExp _emailPattern = RegExp(
  r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
);

/// Returns an error message when [value] is not a plausible email address,
/// or `null` when it looks fine.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Email is required.';
  }
  if (!_emailPattern.hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}
