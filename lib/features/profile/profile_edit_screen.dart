import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/location_metadata.dart';
import '../../models/profile_edit_snapshot.dart';
import '../../models/profile_update_request.dart';
import '../../models/user_detail.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/formatting/display_text.dart';
import '../../theme/app_theme.dart';
import '../location/location_completion_screen.dart';
import 'profile_provider.dart';

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
        appBar: _ProfileEditAppBar(),
        body: SafeArea(
          child: AppAsyncState.loading(message: 'Loading profile details…'),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: const _ProfileEditAppBar(),
        body: SafeArea(
          child: AppAsyncState.error(
            message: error is ApiError
                ? error.message
                : 'Unable to load profile details right now.',
            onRetry: () => ref.invalidate(profileEditSnapshotProvider),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProfileEditAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Edit your profile'));
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
    return Scaffold(
      appBar: const _ProfileEditAppBar(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: Text(_isSaving ? 'Saving…' : 'Save changes'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppTheme.screenPadding(),
            children: [
              _ProfileEditHeader(snapshot: widget.snapshot),
              SizedBox(height: AppTheme.sectionSpacing()),
              _ProfileEditSection(
                title: 'Basics',
                description:
                    'Set the identity and discovery signals people see first.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _genderOptions
                          .map(
                            (option) => ChoiceChip(
                              label: Text(formatDisplayLabel(option)),
                              selected: _selectedGender == option,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedGender = selected ? option : null;
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Interested in',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _genderOptions
                          .map(
                            (option) => FilterChip(
                              label: Text(formatDisplayLabel(option)),
                              selected: _selectedInterestedIn.contains(option),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedInterestedIn.add(option);
                                  } else {
                                    _selectedInterestedIn.remove(option);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.sectionSpacing()),
              _ProfileEditSection(
                title: 'Distance',
                description: 'Choose how far the app should look for matches.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _maxDistanceKm == null
                                ? 'Not set yet'
                                : 'Up to $_maxDistanceKm km',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${_distanceSliderValue.round()} km',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    Slider(
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
                    Text(
                      _maxDistanceKm == null
                          ? 'Move the slider when you want to set a distance.'
                          : 'This value is sent as your maximum distance.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.sectionSpacing()),
              _ProfileEditSection(
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
              SizedBox(height: AppTheme.sectionSpacing()),
              _ProfileEditSection(
                title: 'Location',
                description:
                    'Keep your area current so nearby matches stay relevant.',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Padding(
                    padding: AppTheme.sectionPadding(compact: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _approximateLocation.trim().isEmpty
                                    ? 'Add the area where you want to meet people.'
                                    : 'Showing people near $_approximateLocation.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
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
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppTheme.sectionSpacing()),
              _ProfileEditSection(
                title: 'Fine-tune matching',
                description:
                    'Optional filters stay here so the main edit flow stays quick.',
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('Age and height filters'),
                  subtitle: const Text('Leave blank to keep these flexible.'),
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
              const SizedBox(height: 24),
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
    final verificationText = readOnly.verified
        ? 'Verified profile'
        : 'Verification not complete';
    final subtitleParts = <String>[
      formatDisplayLabel(readOnly.state),
      if (location != null && location.isNotEmpty) location,
      verificationText,
    ];

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surfaceContainerLowest,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: Text(
                _initialFor(readOnly.name),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
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
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleParts.join(' · '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Edit the core details first. Optional filters stay lower on the page.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class _ProfileEditSection extends StatelessWidget {
  const _ProfileEditSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
