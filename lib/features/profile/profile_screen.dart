import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../../api/api_error.dart';
import '../../models/user_detail.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/media/media_url.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
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
          padding: AppTheme.screenPadding(),
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
          SizedBox(height: AppTheme.sectionSpacing()),
          _ProfileSection(
            icon: Icons.notes_rounded,
            title: _aboutTitle(detail),
            value: _bio(detail),
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
          SectionIntroCard(
            icon: Icons.person_search_outlined,
            title: isCurrentUser ? 'Profile details' : 'Shared details',
            description: isCurrentUser
                ? 'Bio, preferences, location, and photos shape how your profile shows up across discovery.'
                : 'A quick read on the basics, preferences, and photos shared on this profile.',
          ),
          SizedBox(height: AppTheme.sectionSpacing()),
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
            title: 'Profile status',
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
    return ShellHero(
      title: _headline(detail),
      description: _heroSummary(detail, isCurrentUser: isCurrentUser),
      eyebrowLabel: isCurrentUser ? 'Your profile' : 'Profile snapshot',
      eyebrowIcon: isCurrentUser
          ? Icons.person_rounded
          : Icons.visibility_outlined,
      centerContent: true,
      header: UserAvatar(
        name: _displayName(detail),
        photoUrl: detail.photoUrls.isEmpty ? null : detail.photoUrls.first,
        radius: 48,
      ),
      badges: [
        ShellHeroPill(
          icon: Icons.verified_user_outlined,
          label: _state(detail),
        ),
        ShellHeroPill(
          icon: Icons.location_on_outlined,
          label: _approximateLocation(detail),
        ),
      ],
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
            if (isComplete) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ShellHeroPill(
                    icon: Icons.check_circle_rounded,
                    label: '$completedCount essentials complete',
                  ),
                  const ShellHeroPill(
                    icon: Icons.explore_rounded,
                    label: 'Ready for discovery',
                  ),
                ],
              ),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.listSpacing()),
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

String _aboutTitle(UserDetail detail) {
  return 'About ${_displayName(detail)}';
}

String _heroSummary(UserDetail detail, {required bool isCurrentUser}) {
  return isCurrentUser
      ? 'A quick view of the details other people can currently discover about you.'
      : 'A snapshot of the profile details this person has chosen to share.';
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
