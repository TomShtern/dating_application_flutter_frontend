import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_detail.dart';
import '../../shared/widgets/app_async_state.dart';
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
            data: (detail) =>
                _ProfileContent(detail: detail, isCurrentUser: _isCurrentUser),
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
  const _ProfileContent({required this.detail, required this.isCurrentUser});

  final UserDetail detail;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _headline(detail),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCurrentUser
                        ? 'This is how your profile appears right now.'
                        : 'Viewing ${_displayName(detail)}\'s profile.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileSection(title: 'Bio', value: _bio(detail)),
          _ProfileSection(title: 'Gender', value: _gender(detail)),
          _ProfileSection(title: 'Interested in', value: _interestedIn(detail)),
          _ProfileSection(
            title: 'Approximate location',
            value: _approximateLocation(detail),
          ),
          _ProfileSection(
            title: 'Distance preference',
            value: _distancePreference(detail),
          ),
          _ProfileSection(title: 'State', value: _state(detail)),
          _PhotoSection(photoUrls: detail.photoUrls),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(title: Text(title), subtitle: Text(value)),
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
        title: 'Photos',
        value: 'No photos added yet.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...photoUrls.map(
              (photoUrl) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl,
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
                      return const _PhotoPlaceholder(
                        message: 'Unable to load photo',
                      );
                    },
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
  const _PhotoPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(message, textAlign: TextAlign.center),
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
