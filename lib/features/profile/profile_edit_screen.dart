import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/location_metadata.dart';
import '../../models/profile_edit_snapshot.dart';
import '../../models/profile_update_request.dart';
import '../../models/user_detail.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../location/location_completion_screen.dart';
import 'profile_provider.dart';

const _profileLavender = Color(0xFF8E6DE8);
const _profileSky = Color(0xFF188DC8);
const _profileMint = Color(0xFF16A871);
const _profileRose = Color(0xFFD95F84);
const _profileSlate = Color(0xFF667085);

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key, this.initialDetail});

  @Deprecated('Profile editing now loads ProfileEditSnapshot from the backend.')
  final UserDetail? initialDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(profileEditSnapshotProvider);

    return snapshotState.when(
      data: (snapshot) => _ProfileEditForm(snapshot: snapshot),
      loading: () => const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Edit profile'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(
                    message: 'Loading profile details…',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppTheme.screenPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRouteHeader(title: 'Edit profile'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load profile details right now.',
                    onRetry: () => ref.invalidate(profileEditSnapshotProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditForm extends ConsumerStatefulWidget {
  const _ProfileEditForm({required this.snapshot});

  final ProfileEditSnapshot snapshot;

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<_ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bioController;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;
  late final TextEditingController _heightController;
  String? _selectedGender;
  late final Set<String> _selectedInterestedIn;
  int? _maxDistanceKm;
  late String _approximateLocation;
  ResolvedLocation? _resolvedLocation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final editable = widget.snapshot.editable;
    _bioController = TextEditingController(text: editable.bio ?? '');
    _selectedGender = _normalizedOrNull(editable.gender ?? '');
    _selectedInterestedIn = _orderedInterestedInValues(
      editable.interestedIn,
    ).toSet();
    _approximateLocation = editable.location?.label ?? '';
    _maxDistanceKm =
        editable.maxDistanceKm != null && editable.maxDistanceKm! > 0
        ? editable.maxDistanceKm
        : null;
    _minAgeController = TextEditingController(
      text: editable.minAge?.toString() ?? '',
    );
    _maxAgeController = TextEditingController(
      text: editable.maxAge?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: editable.heightCm?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              _profileRose.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.12 : 0.04,
              ),
              colorScheme.surface,
            ),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.34),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.22 : 0.06,
                ),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              6,
              AppTheme.pagePadding,
              6,
            ),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _profileRose,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'Saving…' : 'Save changes'),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  8,
                  AppTheme.pagePadding,
                  8,
                ),
                child: const AppRouteHeader(title: 'Edit profile'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    0,
                    AppTheme.pagePadding,
                    AppTheme.navBarHeight + AppTheme.pagePadding,
                  ),
                  children: [
                    _ProfileEditHeader(snapshot: widget.snapshot),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _ProfileEditSection(
                      icon: Icons.badge_outlined,
                      accentColor: _profileLavender,
                      title: 'Basics',
                      description:
                          'Set the identity and discovery signals people see first.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileFieldLabel(title: 'Gender'),
                          const SizedBox(height: 6),
                          _ProfileEditOptionGrid(
                            options: _genderOptions,
                            accentColor: _profileLavender,
                            selectedOptions: {?_selectedGender},
                            onOptionToggled: (option, selected) {
                              setState(() {
                                _selectedGender = selected ? option : null;
                              });
                            },
                          ),
                          const SizedBox(height: AppTheme.compactSectionGap),
                          _ProfileFieldLabel(title: 'Interested in'),
                          const SizedBox(height: 6),
                          _ProfileEditOptionGrid(
                            options: _genderOptions,
                            accentColor: _profileLavender,
                            selectedOptions: _selectedInterestedIn,
                            onOptionToggled: (option, selected) {
                              setState(() {
                                if (selected) {
                                  _selectedInterestedIn.add(option);
                                } else {
                                  _selectedInterestedIn.remove(option);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _ProfileEditSection(
                      icon: Icons.tune_rounded,
                      accentColor: _profileRose,
                      title: 'Distance',
                      description:
                          'Choose how far the app should look for matches.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _maxDistanceKm == null
                                      ? 'Distance not set yet'
                                      : 'Showing matches within',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              if (_maxDistanceKm != null)
                                Text(
                                  '${_distanceSliderValue.round()} km',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: _profileRose,
                                      ),
                                ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _profileRose,
                              inactiveTrackColor: _profileRose.withValues(
                                alpha: 0.18,
                              ),
                              thumbColor: _profileRose,
                              overlayColor: _profileRose.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            child: Slider(
                              value: _distanceSliderValue,
                              min: 5,
                              max: 150,
                              divisions: 29,
                              label: '${_distanceSliderValue.round()} km',
                              onChanged: (value) {
                                setState(() {
                                  _maxDistanceKm = value.round();
                                });
                              },
                            ),
                          ),
                          Text(
                            _maxDistanceKm == null
                                ? 'Move the slider to set how far the app should look.'
                                : 'Anyone further than this won\'t show up in discover.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _ProfileEditSection(
                      icon: Icons.edit_note_rounded,
                      accentColor: _profileSky,
                      title: 'About',
                      description:
                          'Share the details people connect with after the basics.',
                      child: TextFormField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText:
                              'Share a little about your vibe, interests, or ideal first date',
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _ProfileEditSection(
                      icon: Icons.location_on_outlined,
                      accentColor: _profileMint,
                      title: 'Location',
                      description:
                          'Keep your area current so nearby matches stay relevant.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _profileMint.withValues(
                                    alpha: theme.brightness == Brightness.dark
                                        ? 0.18
                                        : 0.10,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: _profileMint,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _approximateLocation.trim().isEmpty
                                      ? 'Add the area where you want to meet people.'
                                      : 'Showing people near $_approximateLocation.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.cardGap),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _profileMint,
                                side: BorderSide(
                                  color: _profileMint.withValues(alpha: 0.26),
                                ),
                              ),
                              onPressed: () async {
                                final resolved = await Navigator.of(context)
                                    .push<ResolvedLocation>(
                                      MaterialPageRoute<ResolvedLocation>(
                                        builder: (context) =>
                                            const LocationCompletionScreen(),
                                      ),
                                    );
                                if (!mounted || resolved == null) {
                                  return;
                                }

                                setState(() {
                                  _approximateLocation = resolved.label;
                                  _resolvedLocation = resolved;
                                });
                              },
                              icon: const Icon(Icons.travel_explore_outlined),
                              label: Text(
                                _approximateLocation.trim().isEmpty
                                    ? 'Choose location'
                                    : 'Update location',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.sectionSpacing()),
                    _ProfileEditSection(
                      icon: Icons.auto_awesome_outlined,
                      accentColor: _profileLavender,
                      title: 'Fine-tune matching',
                      description:
                          'Optional filters stay here so the main edit flow stays quick.',
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _profileLavender.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.12
                                  : 0.05,
                            ),
                            borderRadius: AppTheme.cardRadius,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              14,
                              0,
                              14,
                              14,
                            ),
                            iconColor: _profileLavender,
                            collapsedIconColor: _profileSlate,
                            title: const Text('Age and height filters'),
                            subtitle: const Text(
                              'Leave blank to keep these flexible.',
                            ),
                            children: [
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _minAgeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Minimum preferred age',
                                  hintText: '25',
                                ),
                                validator: _validatePositiveInteger,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _maxAgeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Maximum preferred age',
                                  hintText: '35',
                                ),
                                validator: (value) => _validateMaxAge(
                                  value,
                                  minAgeValue: _minAgeController.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Height (cm)',
                                  hintText: '172',
                                ),
                                validator: _validatePositiveInteger,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = ProfileUpdateRequest(
      bio: _trimmedOrNull(_bioController.text),
      gender: _selectedGender,
      interestedIn: _selectedInterestedIn.isEmpty
          ? null
          : _genderOptions
                .where(_selectedInterestedIn.contains)
                .toList(growable: false),
      maxDistanceKm: _maxDistanceKm,
      minAge: _parseOptionalInt(_minAgeController.text),
      maxAge: _parseOptionalInt(_maxAgeController.text),
      heightCm: _parseOptionalInt(_heightController.text),
      location: _profileLocationRequestFrom(_resolvedLocation),
    );

    try {
      await ref.read(profileControllerProvider).updateProfile(request);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save your profile right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double get _distanceSliderValue => (_maxDistanceKm ?? 50).toDouble();
}

String? _validatePositiveInteger(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    return 'Please enter a valid positive number.';
  }

  return null;
}

String? _validateMaxAge(String? value, {required String minAgeValue}) {
  final integerValidation = _validatePositiveInteger(value);
  if (integerValidation != null) {
    return integerValidation;
  }

  final trimmedMinAge = minAgeValue.trim();
  final trimmedMaxAge = value?.trim() ?? '';
  if (trimmedMinAge.isEmpty || trimmedMaxAge.isEmpty) {
    return null;
  }

  final minAge = int.tryParse(trimmedMinAge);
  final maxAge = int.tryParse(trimmedMaxAge);
  if (minAge == null || maxAge == null) {
    return null;
  }
  if (maxAge < minAge) {
    return 'Maximum age must be greater than or equal to minimum age.';
  }

  return null;
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

ProfileLocationRequest? _profileLocationRequestFrom(
  ResolvedLocation? location,
) {
  if (location == null) {
    return null;
  }

  final countryCode = location.countryCode?.trim();
  final cityName = location.cityName?.trim();
  if (countryCode == null ||
      countryCode.isEmpty ||
      cityName == null ||
      cityName.isEmpty) {
    return null;
  }

  final zipCode = location.zipCode?.trim();
  return ProfileLocationRequest(
    countryCode: countryCode,
    cityName: cityName,
    zipCode: zipCode == null || zipCode.isEmpty ? null : zipCode,
    allowApproximate: location.allowApproximate ?? location.approximate,
  );
}

String? _normalizedOrNull(String value) {
  final normalized = _normalizeGender(value);
  return normalized.isEmpty ? null : normalized;
}

int? _parseOptionalInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return int.tryParse(trimmed);
}

List<String> _orderedInterestedInValues(List<String> values) {
  final normalizedValues = values
      .map(_normalizeGender)
      .where((entry) => entry.isNotEmpty)
      .toSet();

  return _genderOptions
      .where(normalizedValues.contains)
      .toList(growable: false);
}

String _normalizeGender(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final normalized = trimmed.replaceAll(RegExp(r'[\s-]+'), '_').toUpperCase();
  if (normalized == 'NONBINARY') {
    return 'NON_BINARY';
  }

  return normalized;
}

const List<String> _genderOptions = <String>[
  'FEMALE',
  'MALE',
  'NON_BINARY',
  'OTHER',
];

class _ProfileEditHeader extends StatelessWidget {
  const _ProfileEditHeader({required this.snapshot});

  final ProfileEditSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final readOnly = snapshot.readOnly;
    final location = snapshot.editable.location?.label.trim();
    final isDark = theme.brightness == Brightness.dark;
    final photoUrl = readOnly.photoUrls.isEmpty
        ? null
        : readOnly.photoUrls.first;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _profileSky.withValues(alpha: isDark ? 0.10 : 0.035),
          colorScheme.surfaceContainerLow,
        ),
        borderRadius: AppTheme.cardRadius,
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_profileSky, _profileLavender],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: UserAvatar(
                      name: readOnly.name,
                      photoUrl: photoUrl,
                      radius: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        readOnly.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProfileStatusPill(
                            icon: Icons.check_circle_outline_rounded,
                            label: formatDisplayLabel(readOnly.state),
                            color: _profileSky,
                          ),
                          if (location != null && location.isNotEmpty)
                            _ProfileStatusPill(
                              icon: Icons.location_on_outlined,
                              label: location,
                              color: _profileMint,
                            ),
                          _ProfileStatusPill(
                            icon: Icons.photo_library_outlined,
                            label: readOnly.photoUrls.isEmpty
                                ? 'No photos yet'
                                : readOnly.photoUrls.length == 1
                                ? '1 photo'
                                : '${readOnly.photoUrls.length} photos',
                            color: _profileLavender,
                          ),
                          _ProfileStatusPill(
                            icon: readOnly.verified
                                ? Icons.verified_rounded
                                : Icons.verified_outlined,
                            label: readOnly.verified
                                ? 'Verified profile'
                                : 'Verification pending',
                            color: readOnly.verified
                                ? _profileMint
                                : _profileRose,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Edit the core details first. Optional filters stay lower on the page.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditSection extends StatelessWidget {
  const _ProfileEditSection({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          accentColor.withValues(alpha: isDark ? 0.12 : 0.04),
          theme.colorScheme.surfaceContainerLow,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileSectionIconChip(icon: icon, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardGap),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionIconChip extends StatelessWidget {
  const _ProfileSectionIconChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _ProfileStatusPill extends StatelessWidget {
  const _ProfileStatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.09,
        ),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFieldLabel extends StatelessWidget {
  const _ProfileFieldLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ProfileEditOptionGrid extends StatelessWidget {
  const _ProfileEditOptionGrid({
    required this.options,
    required this.accentColor,
    required this.selectedOptions,
    required this.onOptionToggled,
  });

  final List<String> options;
  final Color accentColor;
  final Set<String> selectedOptions;
  final void Function(String option, bool selected) onOptionToggled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.compactCardGap,
        mainAxisSpacing: AppTheme.compactCardGap,
        mainAxisExtent: 48,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        final selected = selectedOptions.contains(option);

        return Material(
          color: selected
              ? accentColor.withValues(alpha: isDark ? 0.24 : 0.12)
              : colorScheme.surface.withValues(alpha: isDark ? 0.72 : 0.9),
          borderRadius: AppTheme.cardRadius,
          child: InkWell(
            borderRadius: AppTheme.cardRadius,
            onTap: () => onOptionToggled(option, !selected),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppTheme.cardRadius,
                border: Border.all(
                  color: selected
                      ? accentColor.withValues(alpha: 0.32)
                      : colorScheme.outlineVariant.withValues(alpha: 0.28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 17,
                      color: selected
                          ? accentColor
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        formatDisplayLabel(option),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? accentColor : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
