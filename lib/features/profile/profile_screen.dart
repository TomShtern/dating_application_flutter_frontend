import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/profile_presentation_context.dart';
import '../../models/user_detail.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../browse/browse_provider.dart';
import '../location/location_completion_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'profile_edit_screen.dart';
import 'profile_provider.dart';

const _profileRose = Color(0xFFD95F84);
const _profileViolet = Color(0xFF8E6DE8);
const _profileMint = Color(0xFF16A871);
const _profileSky = Color(0xFF188DC8);

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: AppTheme.screenPadding(compact: true),
                  child: _CurrentUserProfileIntroCard(
                    onEditProfile: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                    onRefresh: controller.refreshCurrentUserProfile,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppTheme.shellScrollPadding(),
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
        toolbarHeight: 44,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          userName == null && targetUserName == 'this user'
              ? 'Profile'
              : '$targetUserName\'s profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
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
            padding: AppTheme.screenPadding().copyWith(bottom: 40),
            child: _ProfileContent(
              detail: detail,
              isCurrentUser: false,
              presentationContextState: presentationContextState,
              onPrimaryAction: () =>
                  _handleLikeProfile(context, ref, targetUserName),
              onSecondaryAction: () => _handlePassProfile(context, ref),
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

  Future<void> _handleLikeProfile(
    BuildContext context,
    WidgetRef ref,
    String targetUserName,
  ) async {
    try {
      final result = await ref
          .read(browseControllerProvider)
          .likeCandidate(userId!);

      if (!context.mounted) {
        return;
      }

      final message = result.isMatch && result.matchedUserName != null
          ? 'It\'s a match with ${result.matchedUserName}!'
          : result.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiError catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to like $targetUserName right now.')),
      );
    }
  }

  Future<void> _handlePassProfile(BuildContext context, WidgetRef ref) async {
    try {
      final message = await ref
          .read(browseControllerProvider)
          .passCandidate(userId!);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiError catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pass on this profile right now.'),
        ),
      );
    }
  }
}

class _CurrentUserProfileIntroCard extends StatelessWidget {
  const _CurrentUserProfileIntroCard({
    required this.onEditProfile,
    required this.onRefresh,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(context, _profileSky, prominent: true),
        prominent: true,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your profile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep photos, bio, and preferences current.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Refresh profile',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
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
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final UserDetail detail;
  final bool isCurrentUser;
  final AsyncValue<ProfilePresentationContext>? presentationContextState;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFixLocation;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeroCard(detail: detail, isCurrentUser: isCurrentUser),
        SizedBox(height: AppTheme.sectionSpacing()),
        AppGroupLabel(
          title: isCurrentUser ? 'Profile sections' : 'Shared sections',
          accentColor: isCurrentUser ? _profileSky : _profileViolet,
        ),
        if (!isCurrentUser && onPrimaryAction != null) ...[
          SizedBox(height: AppTheme.cardGap),
          Wrap(
            spacing: AppTheme.cardGap,
            runSpacing: AppTheme.cardGap,
            children: [
              FilledButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('Like'),
              ),
              if (onSecondaryAction != null)
                OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Pass for now'),
                ),
            ],
          ),
        ],
        if (!isCurrentUser) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _PhotoSection(
            photoUrls: detail.photoUrls,
            isCurrentUser: false,
            displayName: _displayName(detail),
          ),
        ],
        if (!isCurrentUser && presentationContextState != null) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _PresentationContextSection(state: presentationContextState!),
        ],
        SizedBox(height: AppTheme.sectionSpacing()),
        _ProfileSection(
          icon: Icons.notes_rounded,
          accentColor: _profileRose,
          title: _aboutTitle(detail),
          value: _bio(detail, isCurrentUser: isCurrentUser),
        ),
        SizedBox(height: AppTheme.sectionSpacing()),
        _ProfileDetailsCard(detail: detail, isCurrentUser: isCurrentUser),
        if (isCurrentUser) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _ProfileCompletenessCard(
            detail: detail,
            onEditProfile: onEditProfile,
            onFixLocation: onFixLocation,
          ),
        ],
        if (isCurrentUser) ...[
          SizedBox(height: AppTheme.sectionSpacing()),
          _PhotoSection(
            photoUrls: detail.photoUrls,
            isCurrentUser: true,
            displayName: _displayName(detail),
          ),
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
        accentColor: _profileViolet,
        title: 'Why this profile is shown',
        value: 'Loading recommendation context...',
      ),
      error: (error, stackTrace) => const _ProfileSection(
        icon: Icons.lightbulb_outline_rounded,
        accentColor: _profileViolet,
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

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(context, _profileViolet),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ProfileIconChip(
                  icon: Icons.lightbulb_outline_rounded,
                  color: _profileViolet,
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
              _ProfileReasonTagWrap(reasonTags: contextData.reasonTags),
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
                          color: _profileViolet,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(
          context,
          isCurrentUser ? _profileSky : _profileViolet,
          prominent: true,
        ),
        prominent: true,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [_profileSky, _profileViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: UserAvatar(
                      name: _displayName(detail),
                      photoUrl: detail.photoUrls.isEmpty
                          ? null
                          : detail.photoUrls.first,
                      radius: 38,
                    ),
                  ),
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
                            color: _profileViolet,
                          ),
                          _ProfileMetaPill(
                            icon: Icons.location_on_outlined,
                            label: _approximateLocation(detail),
                            color: _profileMint,
                          ),
                          if (detail.maxDistanceKm > 0)
                            _ProfileMetaPill(
                              icon: Icons.route_outlined,
                              label: _distancePreference(detail),
                              color: _profileSky,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.sectionSpacing(compact: true)),
            Text(
              isCurrentUser
                  ? 'A quick look at what people currently see when they open your profile.'
                  : _heroSummary(detail, isCurrentUser: isCurrentUser),
              style: theme.textTheme.bodyMedium,
            ),
            if (!isCurrentUser) ...[
              SizedBox(height: AppTheme.sectionSpacing(compact: true)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMetaPill extends StatelessWidget {
  const _ProfileMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
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
    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(
          context,
          isCurrentUser ? _profileSky : _profileViolet,
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProfileIconChip(
                  icon: Icons.dashboard_customize_outlined,
                  color: isCurrentUser ? _profileSky : _profileViolet,
                ),
                const SizedBox(width: 12),
                Expanded(
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
                    ],
                  ),
                ),
              ],
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
                  color: _profileSky,
                ),
                _ProfileFactTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Interested in',
                  value: _interestedIn(detail),
                  color: _profileRose,
                ),
                _ProfileFactTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: _approximateLocation(detail),
                  color: _profileMint,
                ),
                _ProfileFactTile(
                  icon: Icons.route_outlined,
                  title: 'Distance',
                  value: _distancePreference(detail),
                  color: _profileViolet,
                ),
                _ProfileFactTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Status',
                  value: _state(detail),
                  color: _profileSky,
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
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 142, maxWidth: 168),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.06),
          borderRadius: AppTheme.cardRadius,
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
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

    final accent = isComplete ? _profileMint : _profileRose;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(context, accent),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProfileIconChip(icon: Icons.tune_rounded, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComplete ? 'Profile ready' : 'Profile completeness',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete
                            ? 'All essentials are in place.'
                            : '$completedCount of ${checklist.length} essentials are filled in.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isComplete) ...[
              SizedBox(height: AppTheme.sectionSpacing()),
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
                              ? accent.withValues(alpha: 0.16)
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
                                ? accent
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
            SizedBox(
              height: isComplete ? AppTheme.compactCardGap : AppTheme.cardGap,
            ),
            Wrap(
              spacing: AppTheme.cardGap,
              runSpacing: AppTheme.cardGap,
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent.withValues(alpha: 0.12),
                    foregroundColor: accent,
                  ),
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(isComplete ? 'Edit profile' : 'Review details'),
                ),
                if (missingLocation)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _profileMint.withValues(alpha: 0.12),
                      foregroundColor: _profileMint,
                    ),
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
    required this.accentColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(context, accentColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileIconChip(icon: icon, color: accentColor),
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
  const _PhotoSection({
    required this.photoUrls,
    required this.isCurrentUser,
    required this.displayName,
  });

  final List<String> photoUrls;
  final bool isCurrentUser;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return _ProfileSection(
        icon: Icons.photo_library_outlined,
        accentColor: _profileViolet,
        title: 'Photos',
        value: isCurrentUser
            ? 'Add a few photos so people can put a face to the profile.'
            : 'No photos shared yet.',
      );
    }

    final photoHeight = isCurrentUser ? 126.0 : 108.0;
    final photoWidth = isCurrentUser ? 156.0 : 132.0;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _profileSurfaceColor(
          context,
          isCurrentUser ? _profileViolet : _profileSky,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ProfileIconChip(
                  icon: Icons.photo_library_outlined,
                  color: _profileSky,
                ),
                const SizedBox(width: 12),
                Text('Photos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _profileViolet.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.18
                          : 0.09,
                    ),
                    borderRadius: AppTheme.chipRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${photoUrls.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _profileViolet,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardGap),
            SizedBox(
              height: photoHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PersonMediaThumbnail(
                    photoUrl: photoUrls[index],
                    name: displayName,
                    height: photoHeight,
                    width: photoWidth,
                    borderRadius: BorderRadius.circular(18),
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

class _ProfileReasonTagWrap extends StatelessWidget {
  const _ProfileReasonTagWrap({required this.reasonTags});

  final List<String> reasonTags;

  @override
  Widget build(BuildContext context) {
    final tags = reasonTags.map(formatDisplayLabel).toList(growable: false);
    final visibleTags = tags.take(3).toList(growable: false);
    final remainingCount = tags.length - visibleTags.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in visibleTags) _ProfileReasonChip(label: tag),
        if (remainingCount > 0)
          _ProfileReasonChip(label: '+$remainingCount more', muted: true),
      ],
    );
  }
}

class _ProfileReasonChip extends StatelessWidget {
  const _ProfileReasonChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? _profileSky : _profileViolet;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08,
        ),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileIconChip extends StatelessWidget {
  const _ProfileIconChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: color),
      ),
    );
  }
}

Color _profileSurfaceColor(
  BuildContext context,
  Color accent, {
  bool prominent = false,
}) {
  final theme = Theme.of(context);
  final alpha = prominent
      ? (theme.brightness == Brightness.dark ? 0.18 : 0.06)
      : (theme.brightness == Brightness.dark ? 0.12 : 0.04);

  return Color.alphaBlend(
    accent.withValues(alpha: alpha),
    theme.colorScheme.surfaceContainerLow,
  );
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
