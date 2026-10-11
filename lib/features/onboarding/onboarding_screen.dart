import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_error.dart';
import '../../models/gender_options.dart';
import '../../models/pace_preferences.dart';
import '../../models/profile_completion_info.dart';
import '../../models/profile_update_request.dart';
import '../../shared/formatting/display_text.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../location/location_completion_screen.dart';
import '../profile/photo_edit_provider.dart';
import '../profile/profile_edit_screen.dart';
import '../profile/profile_provider.dart';

const _maxBioLength = 500; // backend ValidationConfig.maxBioLength
const _minAgeYears = 18; // backend minimum age
const _maxAgeYears = 120;

/// Guided profile setup. Shows one step at a time, always the FIRST field the
/// backend still reports in `missingProfileFields`, so the funnel resumes
/// where the user left off and follows the backend's own order. Each save
/// refreshes the completion snapshot, which moves this screen to the next
/// step; `OnboardingGate` leaves once the profile is complete.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, required this.info});

  final ProfileCompletionInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missing = info.missingProfileFields;
    final stepKey = missing.isEmpty ? '' : missing.first;
    final total = info.requiredProfileFieldCount > 0
        ? info.requiredProfileFieldCount
        : ProfileCompletionInfo.fieldOrder.length;
    final done = (total - missing.length).clamp(0, total - 1);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth(
                MediaQuery.sizeOf(context).width,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    AppTheme.pagePadding,
                    AppTheme.pagePadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${done + 1} of $total',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: done / total),
                    ],
                  ),
                ),
                Expanded(
                  // Keyed so each step starts with fresh local state.
                  child: KeyedSubtree(
                    key: ValueKey(stepKey),
                    child: _stepFor(stepKey, missing),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepFor(String key, List<String> missing) {
    return switch (key) {
      'name' => const _NameStep(),
      'bio' => const _BioStep(),
      'birthDate' => const _BirthDateStep(),
      'gender' => const _GenderStep(),
      'interestedIn' => const _InterestedInStep(),
      'location' => const _LocationStep(),
      'photoUrls' => const _PhotoStep(),
      'pacePreferences' => const _PaceStep(),
      // A field this app version does not know: let the full editor handle it.
      _ => _GenericStep(missing: missing),
    };
  }
}

/// Saving and error state shared by the steps that write the profile.
mixin _SavesProfile<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool saving = false;
  String? error;

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await action();
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> save(ProfileUpdateRequest request) =>
      run(() => ref.read(profileControllerProvider).updateProfile(request));
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.saving = false,
    this.error,
    this.secondary,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Null disables the button.
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool saving;
  final String? error;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        child,
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : onContinue,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(continueLabel),
        ),
        if (secondary != null) ...[const SizedBox(height: 8), secondary!],
      ],
    );
  }
}

class _NameStep extends ConsumerStatefulWidget {
  const _NameStep();

  @override
  ConsumerState<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<_NameStep> with _SavesProfile {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    return _StepFrame(
      title: 'What should we call you?',
      subtitle: 'This is the name other people will see.',
      saving: saving,
      error: error,
      onContinue: name.isEmpty
          ? null
          : () => save(ProfileUpdateRequest(name: name)),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Your name'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class _BioStep extends ConsumerStatefulWidget {
  const _BioStep();

  @override
  ConsumerState<_BioStep> createState() => _BioStepState();
}

class _BioStepState extends ConsumerState<_BioStep> with _SavesProfile {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bio = _controller.text.trim();
    return _StepFrame(
      title: 'Tell people about you',
      subtitle: 'A few lines on what you are like or what you enjoy.',
      saving: saving,
      error: error,
      onContinue: bio.isEmpty
          ? null
          : () => save(ProfileUpdateRequest(bio: bio)),
      child: TextField(
        controller: _controller,
        maxLength: _maxBioLength,
        minLines: 4,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'About you'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class _BirthDateStep extends ConsumerStatefulWidget {
  const _BirthDateStep();

  @override
  ConsumerState<_BirthDateStep> createState() => _BirthDateStepState();
}

class _BirthDateStepState extends ConsumerState<_BirthDateStep>
    with _SavesProfile {
  DateTime? _date;

  Future<void> _pick() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - _minAgeYears, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? latest,
      firstDate: DateTime(now.year - _maxAgeYears, now.month, now.day),
      lastDate: latest,
      helpText: 'Your date of birth',
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// The backend parses an ISO local date.
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final date = _date;
    return _StepFrame(
      title: 'When were you born?',
      subtitle: 'You must be $_minAgeYears or older to use the app.',
      saving: saving,
      error: error,
      onContinue: date == null
          ? null
          : () => save(ProfileUpdateRequest(birthDate: _iso(date))),
      child: OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.cake_outlined),
        label: Text(date == null ? 'Choose your date of birth' : _iso(date)),
      ),
    );
  }
}

class _GenderStep extends ConsumerStatefulWidget {
  const _GenderStep();

  @override
  ConsumerState<_GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends ConsumerState<_GenderStep> with _SavesProfile {
  String? _gender;

  @override
  Widget build(BuildContext context) {
    final gender = _gender;
    return _StepFrame(
      title: 'How do you identify?',
      subtitle: 'Pick the one that fits best.',
      saving: saving,
      error: error,
      onContinue: gender == null
          ? null
          : () => save(ProfileUpdateRequest(gender: gender)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in genderOptions)
            ChoiceChip(
              label: Text(formatDisplayLabel(option)),
              selected: _gender == option,
              onSelected: (_) => setState(() => _gender = option),
            ),
        ],
      ),
    );
  }
}

class _InterestedInStep extends ConsumerStatefulWidget {
  const _InterestedInStep();

  @override
  ConsumerState<_InterestedInStep> createState() => _InterestedInStepState();
}

class _InterestedInStepState extends ConsumerState<_InterestedInStep>
    with _SavesProfile {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Who are you interested in?',
      subtitle: 'Choose everyone you would like to meet.',
      saving: saving,
      error: error,
      onContinue: _selected.isEmpty
          ? null
          : () => save(
              ProfileUpdateRequest(
                interestedIn: genderOptions
                    .where(_selected.contains)
                    .toList(growable: false),
              ),
            ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in genderOptions)
            FilterChip(
              label: Text(formatDisplayLabel(option)),
              selected: _selected.contains(option),
              onSelected: (on) => setState(() {
                on ? _selected.add(option) : _selected.remove(option);
              }),
            ),
        ],
      ),
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep();

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Where are you based?',
      subtitle: 'We use your city to show you people nearby.',
      onContinue: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const LocationCompletionScreen(),
        ),
      ),
      continueLabel: 'Choose your location',
      child: const Icon(Icons.location_on_outlined, size: 48),
    );
  }
}

class _PhotoStep extends ConsumerStatefulWidget {
  const _PhotoStep();

  @override
  ConsumerState<_PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends ConsumerState<_PhotoStep> with _SavesProfile {
  Future<void> _pick(ImageSource source) => run(() async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref.read(photoEditControllerProvider).uploadFromXFile(picked);
  });

  bool get _cameraAvailable =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Add your first photo',
      subtitle: 'A clear photo of you works best. You can add more later.',
      saving: saving,
      error: error,
      continueLabel: 'Choose from gallery',
      onContinue: () => _pick(ImageSource.gallery),
      secondary: _cameraAvailable
          ? OutlinedButton(
              onPressed: saving ? null : () => _pick(ImageSource.camera),
              child: const Text('Take a photo'),
            )
          : null,
      child: const Icon(Icons.photo_camera_outlined, size: 48),
    );
  }
}

class _PaceStep extends ConsumerStatefulWidget {
  const _PaceStep();

  @override
  ConsumerState<_PaceStep> createState() => _PaceStepState();
}

class _PaceStepState extends ConsumerState<_PaceStep> with _SavesProfile {
  PacePreferences _pace = PacePreferences.blank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepFrame(
      title: 'What is your pace?',
      subtitle:
          'Helps us match you with people who like to connect the way you do.',
      saving: saving,
      error: error,
      onContinue: _pace.isComplete
          ? () => save(ProfileUpdateRequest(pacePreferences: _pace))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final question in paceQuestions) ...[
            Text(question.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in question.options.entries)
                  ChoiceChip(
                    label: Text(option.value),
                    selected: question.read(_pace) == option.key,
                    onSelected: (_) => setState(
                      () => _pace = question.write(_pace, option.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _GenericStep extends StatelessWidget {
  const _GenericStep({required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Finish your profile',
      subtitle: missing.isEmpty
          ? 'A few details are still missing.'
          : missing.map(ProfileCompletionInfo.defaultLabel).join('\n'),
      onContinue: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
      ),
      continueLabel: 'Open profile editor',
      child: const SizedBox.shrink(),
    );
  }
}
