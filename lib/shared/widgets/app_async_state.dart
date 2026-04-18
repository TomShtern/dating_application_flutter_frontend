import 'package:flutter/material.dart';

enum _AppAsyncStateVariant { loading, empty, error }

class AppAsyncState extends StatelessWidget {
  const AppAsyncState.loading({super.key, this.message = 'Loading…'})
    : onRetry = null,
      _variant = _AppAsyncStateVariant.loading;

  const AppAsyncState.empty({super.key, required this.message})
    : onRetry = null,
      _variant = _AppAsyncStateVariant.empty;

  const AppAsyncState.error({
    super.key,
    required this.message,
    required this.onRetry,
  }) : _variant = _AppAsyncStateVariant.error;

  final String message;
  final VoidCallback? onRetry;
  final _AppAsyncStateVariant _variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (_variant) {
      _AppAsyncStateVariant.loading => Icons.hourglass_bottom_rounded,
      _AppAsyncStateVariant.empty => Icons.inbox_outlined,
      _AppAsyncStateVariant.error => Icons.error_outline_rounded,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_variant == _AppAsyncStateVariant.loading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (_variant == _AppAsyncStateVariant.error && onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
