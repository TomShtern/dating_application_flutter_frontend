import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum _AppAsyncStateVariant { loading, empty, error }

class AppAsyncState extends StatelessWidget {
  const AppAsyncState.loading({super.key, this.message = 'Loading…'})
    : onRetry = null,
      onRefresh = null,
      _variant = _AppAsyncStateVariant.loading;

  const AppAsyncState.empty({super.key, required this.message, this.onRefresh})
    : onRetry = null,
      _variant = _AppAsyncStateVariant.empty;

  const AppAsyncState.error({
    super.key,
    required this.message,
    required this.onRetry,
  }) : onRefresh = null,
       _variant = _AppAsyncStateVariant.error;

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;
  final _AppAsyncStateVariant _variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = switch (_variant) {
      _AppAsyncStateVariant.loading => 'Setting the mood',
      _AppAsyncStateVariant.empty => 'Nothing here yet',
      _AppAsyncStateVariant.error => 'That did not go to plan',
    };
    final icon = switch (_variant) {
      _AppAsyncStateVariant.loading => Icons.hourglass_bottom_rounded,
      _AppAsyncStateVariant.empty => Icons.inbox_outlined,
      _AppAsyncStateVariant.error => Icons.error_outline_rounded,
    };
    final iconColor = switch (_variant) {
      _AppAsyncStateVariant.loading => colorScheme.onPrimaryContainer,
      _AppAsyncStateVariant.empty => colorScheme.onSecondaryContainer,
      _AppAsyncStateVariant.error => colorScheme.onErrorContainer,
    };
    final highlightColors = switch (_variant) {
      _AppAsyncStateVariant.loading => [
        colorScheme.primaryContainer,
        colorScheme.secondaryContainer,
      ],
      _AppAsyncStateVariant.empty => [
        colorScheme.secondaryContainer,
        colorScheme.tertiaryContainer,
      ],
      _AppAsyncStateVariant.error => [
        colorScheme.errorContainer,
        colorScheme.tertiaryContainer,
      ],
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              child: Card(
                color: colorScheme.surface,
                child: Padding(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: compact ? 48 : 64,
                        height: compact ? 48 : 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: highlightColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: AppTheme.softShadow(context),
                        ),
                        child: Icon(
                          icon,
                          size: compact ? 24 : 32,
                          color: iconColor,
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_variant == _AppAsyncStateVariant.loading) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ],
                      if (_variant == _AppAsyncStateVariant.empty) ...[
                        if (onRefresh != null) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ] else if (!compact) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Check back later for updates.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                      if (_variant == _AppAsyncStateVariant.error &&
                          onRetry != null) ...[
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
              ),
            ),
          ),
        );
      },
    );
  }
}
