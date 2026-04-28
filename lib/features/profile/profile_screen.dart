import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../../api/api_error.dart';
import '../../models/profile_presentation_context.dart';
import '../../models/user_detail.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/media/media_url.dart';
import '../../shared/widgets/highlight_tag_row.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../location/location_completion_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'profile_edit_screen.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen.currentUser({super.key}) : userId = null, userName = null;

  const ProfileScreen.otherUser({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String? userId;
  final String? userName;

  bool get _isCurrentUser => userId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = _isCurrentUser
        ? ref.watch(profileProvider)
        : ref.watch(otherUserProfileProvider(userId!));
    final presentationContextState = _isCurrentUser
        ? null
        : ref.watch(presentationContextProvider(userId!));
    final controller = ref.read(profileControllerProvider);
    final targetUserName = profileState.maybeWhen(
      data: _displayName,
      orElse: () => userName ?? 'this user',
    );

    if (_isCurrentUser) {
      return SafeArea(
        top: false,
        child: profileState.when(
          data: (detail) {
            final readinessLabel = _profileReadiness(detail).label;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShellHero(
                  compact: true,
                  eyebrowLabel: 'Your profile',
                  header: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const ProfileEditScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Refresh profile',
                        onPressed: controller.refreshCurrentUserProfile,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  title: _headline(detail),
                  description: readinessLabel,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppTheme.screenPadding(),
                    child: _ProfileContent(
                      detail: detail,
                      isCurrentUser: true,
                      onEditProfile: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        );
                      },
                      onFixLocation: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const LocationCompletionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const AppAsyncState.loading(message: 'Loading profile…'),
          ),
          error: (error, stackTrace) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load profile right now.',
              onRetry: controller.refreshCurrentUserProfile,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          SafetyActionsButton(
            targetUserId: userId!,
            targetUserName: targetUserName,
            onCompleted: (context, outcome) {
              if (outcome.removesRelationship) {
                Navigator.of(context).maybePop();
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: () => controller.refreshOtherUserProfile(userId!),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: profileState.when(
          data: (detail) => SingleChildScrollView(
            padding: AppTheme.screenPadding(),
            child: _ProfileContent(
              detail: detail,
              isCurrentUser: false,
              presentationContextState: presentationContextState,
            ),
          ),
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const AppAsyncState.loading(message: 'Loading profile…'),
          ),
          error: (error, stackTrace) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load profile right now.',
              onRetry: () => controller.refreshOtherUserProfile(userId!),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.detail,
    required this.isCurrentUser,
    this.presentationContextState,
    this.onEditProfile,
    this.onFixLocation,
  });

  final UserDetail detail;
  final bool isCurrentUser;
  final AsyncValue<ProfilePresentationContext>? presentationContextState;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFixLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeroCard(detail: detail, isCurrentUser: isCurrentUser),
        if (!isCurrentUser) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _PhotoSection(photoUrls: detail.photoUrls),
        ],
        if (!isCurrentUser && presentationContextState != null) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _PresentationContextSection(state: presentationContextState!),
        ],
        SizedBox(height: AppTheme.sectionSpacing()),
        _ProfileSection(
          icon: Icons.notes_rounded,
          title: _aboutTitle(detail),
          value: _bio(detail, isCurrentUser: isCurrentUser),
        ),
        if (isCurrentUser) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _ProfileCompletenessCard(
            detail: detail,
            onEditProfile: onEditProfile,
            onFixLocation: onFixLocation,
          ),
        ],
        SizedBox(height: AppTheme.sectionSpacing()),
        _ProfileDetailsCard(detail: detail, isCurrentUser: isCurrentUser),
        if (isCurrentUser) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _PhotoSection(photoUrls: detail.photoUrls),
        ],
      ],
    );
  }
}

class _PresentationContextSection extends StatelessWidget {
  const _PresentationContextSection({required this.state});

  final AsyncValue<ProfilePresentationContext> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (contextData) => _PresentationContextCard(contextData: contextData),
      loading: () => const _ProfileSection(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Why this profile is shown',
        value: 'Loading recommendation context...',
      ),
      error: (error, stackTrace) => const _ProfileSection(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Why this profile is shown',
        value: 'Recommendation context is unavailable right now.',
      ),
    );
  }
}

class _PresentationContextCard extends StatelessWidget {
  const _PresentationContextCard({required this.contextData});

  final ProfilePresentationContext contextData;

  @override
  Widget build(BuildContext context) {
    final details = contextData.details;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Why this profile is shown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(contextData.summary),
            if (contextData.reasonTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              HighlightTagRow(
                tags: contextData.reasonTags
                    .map(formatDisplayLabel)
                    .toList(growable: false),
                icon: Icons.sell_outlined,
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(detail)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.detail, required this.isCurrentUser});

  final UserDetail detail;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readiness = _profileReadiness(detail);

    return Card(
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: _displayName(detail),
                  photoUrl: detail.photoUrls.isEmpty
                      ? null
                      : detail.photoUrls.first,
                  radius: 38,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUser) ...[
                        Text(
                          'Profile snapshot',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        _headline(detail),
                        style: isCurrentUser
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: AppTheme.cardGap,
                        runSpacing: 8,
                        children: [
                          _ProfileMetaPill(
                            icon: Icons.verified_user_outlined,
                            label: _state(detail),
                          ),
                          _ProfileMetaPill(
                            icon: Icons.location_on_outlined,
                            label: _approximateLocation(detail),
                          ),
                          if (detail.maxDistanceKm > 0)
                            _ProfileMetaPill(
                              icon: Icons.route_outlined,
                              label: _distancePreference(detail),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isCurrentUser) ...[
              SizedBox(height: AppTheme.sectionSpacing()),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: readiness.progress,
                ),
              ),
            ] else ...[
              SizedBox(height: AppTheme.sectionSpacing(compact: true)),
              Text(
                _heroSummary(detail, isCurrentUser: isCurrentUser),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMetaPill extends StatelessWidget {
  const _ProfileMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.detail,
    required this.isCurrentUser,
  });

  final UserDetail detail;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentUser ? 'Profile details' : 'Shared details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              isCurrentUser
                  ? 'The signals currently shaping discovery.'
                  : 'The basics this person has chosen to share.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: AppTheme.sectionSpacing(compact: true)),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProfileFactTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Gender',
                  value: _gender(detail),
                ),
                _ProfileFactTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Interested in',
                  value: _interestedIn(detail),
                ),
                _ProfileFactTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: _approximateLocation(detail),
                ),
                _ProfileFactTile(
                  icon: Icons.route_outlined,
                  title: 'Distance',
                  value: _distancePreference(detail),
                ),
                _ProfileFactTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Status',
                  value: _state(detail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFactTile extends StatelessWidget {
  const _ProfileFactTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 142, maxWidth: 168),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.26),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCompletenessCard extends StatelessWidget {
  const _ProfileCompletenessCard({
    required this.detail,
    required this.onEditProfile,
    required this.onFixLocation,
  });

  final UserDetail detail;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFixLocation;

  @override
  Widget build(BuildContext context) {
    final checklist = <String, bool>{
      'Add a bio': detail.bio.trim().isNotEmpty,
      'Set match preferences': detail.interestedIn.isNotEmpty,
      'Choose a location': detail.approximateLocation.trim().isNotEmpty,
      'Add at least one photo': detail.photoUrls.isNotEmpty,
    };
    final completedCount = checklist.values.where((done) => done).length;
    final progress = checklist.isEmpty
        ? 0.0
        : completedCount / checklist.length;
    final isComplete = progress >= 1;
    final missingLocation = !checklist['Choose a location']!;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.tune_rounded, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComplete ? 'Profile ready' : 'Profile completeness',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete
                            ? 'All of the essentials are in place. Refresh it whenever you want to keep things feeling current.'
                            : '$completedCount of ${checklist.length} essentials are filled in.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.sectionSpacing()),
            if (isComplete)
              ...[
            ] else ...[
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(minHeight: 10, value: progress),
              ),
              SizedBox(height: AppTheme.sectionSpacing()),
              ...checklist.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: entry.value
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            entry.value
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: entry.value
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.key, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.cardGap),
            Wrap(
              spacing: AppTheme.cardGap,
              runSpacing: AppTheme.cardGap,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Review details'),
                ),
                if (missingLocation)
                  FilledButton.tonalIcon(
                    onPressed: onFixLocation,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Fix location'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return const _ProfileSection(
        icon: Icons.photo_library_outlined,
        title: 'Photos',
        value: 'No photos added yet.',
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Photos', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.cardGap),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: UserAvatarPhoto(
                    photoUrl: photoUrls[index],
                    height: 126,
                    width: 156,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.message,
    this.height = 220,
    this.width = double.infinity,
  });

  final String message;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProfileReadiness {
  const _ProfileReadiness({required this.progress, required this.label});

  final double progress;
  final String label;
}

class UserAvatarPhoto extends ConsumerWidget {
  const UserAvatarPhoto({
    super.key,
    required this.photoUrl,
    this.height = 200,
    this.width = double.infinity,
  });

  final String photoUrl;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPhotoUrl = resolveMediaUrl(
      rawUrl: photoUrl,
      baseUrl: ref.watch(appConfigProvider).baseUrl,
    );

    if (resolvedPhotoUrl == null) {
      return _PhotoPlaceholder(
        message: 'Unable to load photo',
        height: height,
        width: width,
      );
    }

    return Image.network(
      resolvedPhotoUrl,
      height: height,
      width: width,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _PhotoPlaceholder(
          message: 'Loading photo…',
          height: height,
          width: width,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _PhotoPlaceholder(
          message: 'Unable to load photo',
          height: height,
          width: width,
        );
      },
    );
  }
}

String _displayName(UserDetail detail) {
  final name = detail.name.trim();
  if (name.isEmpty) {
    return 'Unknown user';
  }

  return name;
}

String _headline(UserDetail detail) {
  final name = _displayName(detail);
  if (detail.age > 0) {
    return '$name, ${detail.age}';
  }

  return name;
}

String _bio(UserDetail detail, {required bool isCurrentUser}) {
  final bio = detail.bio.trim();
  if (bio.isEmpty) {
    return isCurrentUser
        ? 'Add a short bio so people get a feel for you.'
        : 'No bio shared yet.';
  }

  return bio;
}

String _aboutTitle(UserDetail detail) {
  return 'About ${_displayName(detail)}';
}

String _heroSummary(UserDetail detail, {required bool isCurrentUser}) {
  return isCurrentUser
      ? 'A quick view of the details other people can currently discover about you.'
      : 'A snapshot of the profile details this person has chosen to share.';
}

_ProfileReadiness _profileReadiness(UserDetail detail) {
  final checklist = <bool>[
    detail.bio.trim().isNotEmpty,
    detail.interestedIn.isNotEmpty,
    detail.approximateLocation.trim().isNotEmpty,
    detail.photoUrls.isNotEmpty,
  ];
  final completed = checklist.where((done) => done).length;
  final total = checklist.length;
  final progress = total == 0 ? 0.0 : completed / total;

  return _ProfileReadiness(
    progress: progress,
    label: completed == total
        ? 'Profile ready · $completed of $total essentials complete'
        : '$completed of $total essentials complete',
  );
}

String _gender(UserDetail detail) {
  return formatDisplayLabel(detail.gender);
}

String _interestedIn(UserDetail detail) {
  return formatDisplayLabelList(detail.interestedIn);
}

String _approximateLocation(UserDetail detail) {
  final location = detail.approximateLocation.trim();
  if (location.isEmpty) {
    return 'Location not shared';
  }

  return location;
}

String _distancePreference(UserDetail detail) {
  if (detail.maxDistanceKm <= 0) {
    return 'Distance preference not set';
  }

  return '${detail.maxDistanceKm} km';
}

String _state(UserDetail detail) {
  return formatDisplayLabel(detail.state, fallback: 'Unknown');
}
