import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/verification_result.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../theme/app_theme.dart';
import 'verification_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppTheme.screenPadding(),
          children: [
            ShellHero(
              eyebrowLabel: 'Contact check',
              eyebrowIcon: Icons.verified_user_outlined,
              title: 'Verify your contact details',
              description:
                  'We\'ll send a one-time code so you can confirm this email address or phone number belongs to you.',
              badges: [
                ShellHeroPill(
                  icon: _method == 'EMAIL'
                      ? Icons.email_outlined
                      : Icons.sms_outlined,
                  label: formatDisplayLabel(_method),
                ),
                const ShellHeroPill(
                  icon: Icons.lock_outline_rounded,
                  label: 'One-time code flow',
                ),
                if (kDebugMode)
                  const ShellHeroPill(
                    icon: Icons.science_outlined,
                    label: 'Debug helpers stay separate',
                  ),
              ],
            ),
            SizedBox(height: AppTheme.sectionSpacing()),
            const SectionIntroCard(
              icon: Icons.route_outlined,
              title: 'How it works',
              description:
                  'Choose a contact method, send the code, and confirm it here to finish the verification step.',
              badges: [
                ShellHeroPill(
                  icon: Icons.looks_one_rounded,
                  label: 'Pick email or phone',
                ),
                ShellHeroPill(
                  icon: Icons.looks_two_rounded,
                  label: 'Send one-time code',
                ),
                ShellHeroPill(
                  icon: Icons.looks_3_rounded,
                  label: 'Confirm to finish',
                ),
              ],
            ),
            SizedBox(height: AppTheme.sectionSpacing()),
            _VerificationStepCard(
              title: 'Start verification',
              description:
                  'Pick where we should send the code. You can change methods any time before you send it.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: _method == 'EMAIL' ? 'Email' : 'Phone',
                      hintText: _method == 'EMAIL'
                          ? 'you@example.com'
                          : '+1 555 555 5555',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _starting ? null : _handleStart,
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(
                      _starting ? 'Starting…' : 'Send verification code',
                    ),
                  ),
                ],
              ),
            ),
            if (startResult != null) ...[
              SizedBox(height: AppTheme.sectionSpacing()),
              _VerificationStepCard(
                title: 'Enter the code',
                description:
                    'We have a code ready for ${formatDisplayLabel(startResult.method)} at ${startResult.contact}. Enter it below to finish verification.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ShellHeroPill(
                          icon: Icons.mark_email_read_outlined,
                          label: formatDisplayLabel(startResult.method),
                        ),
                        ShellHeroPill(
                          icon: Icons.alternate_email_outlined,
                          label: startResult.contact,
                        ),
                      ],
                    ),
                    if (kDebugMode &&
                        startResult.devVerificationCode.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DevelopmentOnlyCodeCard(
                        code: startResult.devVerificationCode,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Verification code',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _confirming ? null : _handleConfirm,
                      child: Text(
                        _confirming ? 'Confirming…' : 'Confirm verification',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (confirmResult != null) ...[
              SizedBox(height: AppTheme.sectionSpacing()),
              _VerificationOutcomeCard(result: confirmResult),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleStart() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an email or phone number first.')),
      );
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

class _VerificationStepCard extends StatelessWidget {
  const _VerificationStepCard({
    required this.title,
    required this.description,
    required this.child,
  });

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
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 18),
            child,
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
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text('Development only', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This preview code is only visible in debug builds to unblock local testing.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SelectableText(code, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
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

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color:
            (verified
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest)
                .withValues(alpha: 0.72),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: verified ? colorScheme.primary : colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  verified
                      ? Icons.verified_rounded
                      : Icons.error_outline_rounded,
                  color: verified ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verified ? 'Verification complete' : 'Verification pending',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.verifiedAt == null
                        ? (verified
                              ? 'Your contact details are now confirmed.'
                              : 'No verification timestamp was returned yet.')
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
