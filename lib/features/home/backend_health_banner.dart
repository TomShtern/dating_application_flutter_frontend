import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import 'backend_health_provider.dart';

class BackendHealthBanner extends ConsumerWidget {
  const BackendHealthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthStatus = ref.watch(backendHealthProvider);

    return healthStatus.when(
      data: (status) {
        final colorScheme = Theme.of(context).colorScheme;
        final background = status.isHealthy
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer;
        final foreground = status.isHealthy
            ? colorScheme.onPrimaryContainer
            : colorScheme.onErrorContainer;
        final label = status.isHealthy
            ? 'Backend online'
            : 'Backend reported issues';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                status.isHealthy
                    ? Icons.cloud_done_outlined
                    : Icons.warning_amber_rounded,
                color: foreground,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(backendHealthProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (error, stackTrace) {
        final message = error is ApiError
            ? error.message
            : 'Backend unavailable';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backend unavailable',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(message),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(backendHealthProvider),
                child: const Text('Retry health check'),
              ),
            ],
          ),
        );
      },
    );
  }
}
