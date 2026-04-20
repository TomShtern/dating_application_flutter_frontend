import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/verification_result.dart';
import '../../shared/formatting/date_formatting.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start verification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the backend-supported email or phone flow. In development, the generated code is surfaced so you can finish the flow without leaving the app.',
                    ),
                    const SizedBox(height: 16),
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
            ),
            if (_startResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification code ready',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Method: ${_startResult!.method}'),
                      Text('Contact: ${_startResult!.contact}'),
                      const SizedBox(height: 12),
                      SelectableText(
                        _startResult!.devVerificationCode,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
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
              ),
            ],
            if (_confirmResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(
                    _confirmResult!.verified
                        ? Icons.verified_rounded
                        : Icons.error_outline_rounded,
                  ),
                  title: Text(
                    _confirmResult!.verified
                        ? 'You are verified'
                        : 'Verification still pending',
                  ),
                  subtitle: Text(
                    _confirmResult!.verifiedAt == null
                        ? 'No verification timestamp was returned.'
                        : 'Verified at ${formatDateTimeStamp(_confirmResult!.verifiedAt!)}',
                  ),
                ),
              ),
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
        _codeController.text = result.devVerificationCode;
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
