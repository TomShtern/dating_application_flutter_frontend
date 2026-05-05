import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/verification_result.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../theme/app_theme.dart';
import 'verification_provider.dart';

const _verificationTrust = Color(0xFF16A871);
const _verificationSky = Color(0xFF188DC8);
const _verificationViolet = Color(0xFF7C4DFF);

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _contactController = TextEditingController();
  final _codeController = TextEditingController();
  String _method = 'EMAIL';
  bool _starting = false;
  bool _confirming = false;
  VerificationStartResult? _startResult;
  VerificationConfirmationResult? _confirmResult;

  @override
  void dispose() {
    _contactController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startResult = _startResult;
    final confirmResult = _confirmResult;
    final progressValue = confirmResult?.verified == true
        ? 1.0
        : startResult == null
        ? 0.34
        : 0.76;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppTheme.screenPadding(),
          children: [
            const AppRouteHeader(title: 'Verification'),
            const SizedBox(height: 8),
            SectionIntroCard(
              icon: Icons.verified_user_rounded,
              title: 'Verify your account',
              description:
                  'Confirm your email or phone in two short steps. Verified profiles show a clearer trust signal to matches.',
              iconBackgroundColor: _verificationTrust.withValues(alpha: 0.12),
              iconColor: _verificationTrust,
              badges: const [
                ShellHeroPill(
                  icon: Icons.verified_outlined,
                  label: 'Verified badge',
                ),
                ShellHeroPill(
                  icon: Icons.security_outlined,
                  label: 'Trust signal',
                ),
                ShellHeroPill(
                  icon: Icons.timelapse_rounded,
                  label: 'Two quick steps',
                ),
              ],
            ),
            const SizedBox(height: AppTheme.compactCardGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.compactCardPadding,
              ),
              child: _VerificationProgressBar(
                value: progressValue,
                color: _verificationTrust,
              ),
            ),
            const SizedBox(height: AppTheme.compactCardGap),
            _VerificationStepCard(
              stepLabel: 'Request code',
              title: 'Start verification',
              description:
                  'Choose email or phone, then we\'ll send a code there.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'EMAIL',
                        label: Text('Email'),
                      ),
                      ButtonSegment<String>(
                        value: 'PHONE',
                        label: Text('Phone'),
                      ),
                    ],
                    selected: {_method},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _method = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.cardGap),
                  TextField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: _method == 'EMAIL' ? 'Email' : 'Phone',
                      hintText: _method == 'EMAIL'
                          ? 'you@example.com'
                          : '+1 555 555 5555',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(22),
                        ),
                        borderSide: BorderSide(
                          color: _verificationTrust,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.cardGap),
                  FilledButton.icon(
                    onPressed: _starting ? null : _handleStart,
                    style: _verificationButtonStyle(context),
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(
                      _starting ? 'Starting…' : 'Send verification code',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.compactCardGap),
            const _VerificationTrustSection(),
            if (startResult != null) ...[
              const SizedBox(height: AppTheme.compactCardGap),
              _VerificationStepCard(
                stepLabel: 'Confirm code',
                title: 'Enter the code',
                description:
                    'Enter the code sent to ${startResult.contact} to finish verifying your ${formatDisplayLabel(startResult.method).toLowerCase()}.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppTheme.cardGap,
                      runSpacing: AppTheme.cardGap,
                      children: [
                        _VerificationInfoChip(
                          icon: startResult.method.toUpperCase() == 'PHONE'
                              ? Icons.phone_outlined
                              : Icons.mark_email_read_outlined,
                          label: formatDisplayLabel(startResult.method),
                        ),
                        _VerificationInfoChip(
                          icon: Icons.alternate_email_outlined,
                          label: startResult.contact,
                        ),
                      ],
                    ),
                    if (kDebugMode &&
                        startResult.devVerificationCode.trim().isNotEmpty) ...[
                      const SizedBox(height: AppTheme.cardGap),
                      _DevelopmentOnlyCodeCard(
                        code: startResult.devVerificationCode,
                      ),
                    ],
                    const SizedBox(height: AppTheme.cardGap),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Verification code',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(22),
                          ),
                          borderSide: BorderSide(
                            color: _verificationTrust,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardGap),
                    FilledButton(
                      onPressed: _confirming ? null : _handleConfirm,
                      style: _verificationButtonStyle(context),
                      child: Text(
                        _confirming ? 'Confirming…' : 'Confirm verification',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (confirmResult != null) ...[
              const SizedBox(height: AppTheme.compactCardGap),
              _VerificationOutcomeCard(result: confirmResult),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleStart() async {
    final contact = _contactController.text.trim();
    final validationMessage = _contactValidationMessage(contact);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() {
      _starting = true;
      _confirmResult = null;
    });

    try {
      final result = await ref
          .read(verificationControllerProvider)
          .start(method: _method, contact: contact);
      if (!mounted) {
        return;
      }
      setState(() {
        _startResult = result;
        if (kDebugMode) {
          _codeController.text = result.devVerificationCode;
        }
      });
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
        });
      }
    }
  }

  String? _contactValidationMessage(String contact) {
    if (contact.isEmpty) {
      return 'Enter an email or phone number first.';
    }

    if (_method == 'EMAIL') {
      final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailPattern.hasMatch(contact)) {
        return 'Enter a valid email address.';
      }
      return null;
    }

    final digitCount = RegExp(r'\d').allMatches(contact).length;
    if (digitCount < 7) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  Future<void> _handleConfirm() async {
    final verificationCode = _codeController.text.trim();
    if (verificationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the verification code first.')),
      );
      return;
    }

    setState(() {
      _confirming = true;
    });

    try {
      final result = await ref
          .read(verificationControllerProvider)
          .confirm(verificationCode: verificationCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _confirmResult = result;
      });
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _confirming = false;
        });
      }
    }
  }
}

ButtonStyle _verificationButtonStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.surfaceContainerHighest;
      }

      return _verificationTrust;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.onSurface.withValues(alpha: 0.42);
      }

      return Colors.white;
    }),
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
}

class _VerificationProgressBar extends StatelessWidget {
  const _VerificationProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTheme.chipRadius,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return LinearProgressIndicator(
            value: animatedValue,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.16),
          );
        },
      ),
    );
  }
}

class _VerificationStepCard extends StatelessWidget {
  const _VerificationStepCard({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.child,
  });

  final String stepLabel;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _verificationSky.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.10
                : 0.04,
          ),
          colorScheme.surfaceContainerLow,
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(stepLabel),
            const SizedBox(height: AppTheme.cardGap),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.compactCardGap),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.cardGap),
            child,
          ],
        ),
      ),
    );
  }
}

class _VerificationTrustSection extends StatelessWidget {
  const _VerificationTrustSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _verificationTrust.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.12
                : 0.05,
          ),
          colorScheme.surfaceContainerLow,
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('How it works'),
            SizedBox(height: AppTheme.cardGap),
            _TrustBullet(
              icon: Icons.mail_outline_rounded,
              text: 'We send a one-time code to your email or phone.',
            ),
            SizedBox(height: AppTheme.compactCardGap),
            _TrustBullet(
              icon: Icons.lock_outline_rounded,
              text: 'The code confirms you own the contact method.',
            ),
            SizedBox(height: AppTheme.compactCardGap),
            _TrustBullet(
              icon: Icons.badge_outlined,
              text: 'Your profile gets a Verified badge visible to matches.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: AppTheme.chipRadius,
            child: SizedBox(
              width: 3,
              child: ColoredBox(
                color: _verificationTrust.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.cardGap),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _verificationTrust,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBullet extends StatelessWidget {
  const _TrustBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _verificationTrust.withValues(alpha: 0.8)),
        const SizedBox(width: AppTheme.cardGap),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _VerificationInfoChip extends StatelessWidget {
  const _VerificationInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _verificationViolet.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.14
                : 0.06,
          ),
          colorScheme.surfaceContainerHighest,
        ),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.cardGap,
          vertical: AppTheme.compactCardGap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _verificationViolet),
            const SizedBox(width: AppTheme.compactCardGap),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentOnlyCodeCard extends StatelessWidget {
  const _DevelopmentOnlyCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DeveloperOnlyCalloutCard(
      title: 'Test code',
      description: 'Shown only in debug builds for local testing.',
      child: SelectableText(code, style: theme.textTheme.headlineSmall),
    );
  }
}

class _VerificationOutcomeCard extends StatelessWidget {
  const _VerificationOutcomeCard({required this.result});

  final VerificationConfirmationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verified = result.verified;

    if (verified) {
      final textColor = colorScheme.onPrimary;

      return DecoratedBox(
        decoration: AppTheme.surfaceDecoration(
          context,
          gradient: AppTheme.accentGradient(context),
          prominent: true,
        ),
        child: Padding(
          padding: AppTheme.sectionPadding(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_rounded, size: 32, color: textColor),
              const SizedBox(width: AppTheme.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account verified',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardGap),
                    Text(
                      result.verifiedAt == null
                          ? 'Your contact details are confirmed and your profile can show the Verified badge to matches.'
                          : 'Verified at ${formatDateTimeStamp(result.verifiedAt!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: AppTheme.cardPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification pending',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.cardGap),
                  Text(
                    result.verifiedAt == null
                        ? 'No verification timestamp was returned yet.'
                        : 'Verified at ${formatDateTimeStamp(result.verifiedAt!)}',
                    style: theme.textTheme.bodyMedium,
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
