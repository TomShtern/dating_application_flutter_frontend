import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../../api/api_error.dart';
import '../../models/user_detail.dart';
import '../../shared/media/media_url.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
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
    final controller = ref.read(profileControllerProvider);
    final title = _isCurrentUser
        ? 'My profile'
        : profileState.maybeWhen(
            data: _displayName,
            orElse: () => userName ?? 'Profile',
          );
    final targetUserName = profileState.maybeWhen(
      data: _displayName,
      orElse: () => userName ?? 'this user',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isCurrentUser)
            profileState.maybeWhen(
              data: (detail) => IconButton(
                tooltip: 'Edit profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          ProfileEditScreen(initialDetail: detail),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              orElse: SizedBox.shrink,
            ),
          if (!_isCurrentUser)
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
            onPressed: () {
              if (_isCurrentUser) {
                controller.refreshCurrentUserProfile();
                return;
              }

              controller.refreshOtherUserProfile(userId!);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: profileState.when(
            data: (detail) => _ProfileContent(
              detail: detail,
              isCurrentUser: _isCurrentUser,
              onEditProfile: _isCurrentUser
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              ProfileEditScreen(initialDetail: detail),
                        ),
                      );
                    }
                  : null,
              onFixLocation: _isCurrentUser
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const LocationCompletionScreen(),
                        ),
                      );
                    }
                  : null,
            ),
            loading: () =>
                const AppAsyncState.loading(message: 'Loading profile…'),
            error: (error, stackTrace) => AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load profile right now.',
              onRetry: () {
                if (_isCurrentUser) {
                  controller.refreshCurrentUserProfile();
                  return;
                }

                controller.refreshOtherUserProfile(userId!);
              },
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
    this.onEditProfile,
    this.onFixLocation,
  });

  final UserDetail detail;
  final bool isCurrentUser;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFixLocation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeroCard(detail: detail, isCurrentUser: isCurrentUser),
          if (isCurrentUser) ...[
            const SizedBox(height: 18),
            _ProfileCompletenessCard(
              detail: detail,
              onEditProfile: onEditProfile,
              onFixLocation: onFixLocation,
            ),
          ],
          const SizedBox(height: 18),
          _ProfileSection(
            icon: Icons.notes_rounded,
            title: 'Bio',
            value: _bio(detail),
          ),
          _ProfileSection(
            icon: Icons.person_outline_rounded,
            title: 'Gender',
            value: _gender(detail),
          ),
          _ProfileSection(
            icon: Icons.favorite_outline_rounded,
            title: 'Interested in',
            value: _interestedIn(detail),
          ),
          _ProfileSection(
            icon: Icons.location_on_outlined,
            title: 'Approximate location',
            value: _approximateLocation(detail),
          ),
          _ProfileSection(
            icon: Icons.route_outlined,
            title: 'Distance preference',
            value: _distancePreference(detail),
          ),
          _ProfileSection(
            icon: Icons.verified_user_outlined,
            title: 'State',
            value: _state(detail),
          ),
          _PhotoSection(photoUrls: detail.photoUrls),
        ],
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

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: AppTheme.heroGradient(context),
        prominent: true,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -6,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.tertiary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                UserAvatar(
                  name: _displayName(detail),
                  photoUrl: detail.photoUrls.isEmpty
                      ? null
                      : detail.photoUrls.first,
                  radius: 48,
                ),
                const SizedBox(height: 18),
                Text(
                  _headline(detail),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isCurrentUser
                      ? 'This is how your profile appears right now.'
                      : 'Viewing ${_displayName(detail)}\'s profile.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ProfileMetaPill(
                      icon: Icons.verified_user_outlined,
                      label: _state(detail),
                    ),
                    _ProfileMetaPill(
                      icon: Icons.location_on_outlined,
                      label: _approximateLocation(detail),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      decoration: AppTheme.glassDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(18),
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
                        'Profile completeness',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount of ${checklist.length} essentials are filled in.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              child: LinearProgressIndicator(minHeight: 10, value: progress),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: colorScheme.primary),
            ),
          ),
          title: Text(title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(value),
          ),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 16),
            ...photoUrls.map(
              (photoUrl) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: UserAvatarPhoto(photoUrl: photoUrl),
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
  const _PhotoPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
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

class UserAvatarPhoto extends ConsumerWidget {
  const UserAvatarPhoto({super.key, required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPhotoUrl = resolveMediaUrl(
      rawUrl: photoUrl,
      baseUrl: ref.watch(appConfigProvider).baseUrl,
    );

    if (resolvedPhotoUrl == null) {
      return const _PhotoPlaceholder(message: 'Unable to load photo');
    }

    return Image.network(
      resolvedPhotoUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const _PhotoPlaceholder(message: 'Loading photo…');
      },
      errorBuilder: (context, error, stackTrace) {
        return const _PhotoPlaceholder(message: 'Unable to load photo');
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

String _bio(UserDetail detail) {
  final bio = detail.bio.trim();
  if (bio.isEmpty) {
    return 'No bio added yet.';
  }

  return bio;
}

String _gender(UserDetail detail) {
  final gender = detail.gender.trim();
  if (gender.isEmpty) {
    return 'Not specified';
  }

  return gender;
}

String _interestedIn(UserDetail detail) {
  if (detail.interestedIn.isEmpty) {
    return 'Not specified';
  }

  return detail.interestedIn.join(', ');
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
  final state = detail.state.trim();
  if (state.isEmpty) {
    return 'UNKNOWN';
  }

  return state;
}
