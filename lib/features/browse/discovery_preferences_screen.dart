import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/discovery_preferences.dart';
import '../../models/profile_edit_snapshot.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../theme/app_theme.dart';
import 'discovery_preferences_provider.dart';

const _prefRose = Color(0xFFE24A68);
const _prefSky = Color(0xFF188DC8);
const _prefAmber = Color(0xFFD98914);
const _prefMint = Color(0xFF16A871);
const _prefSlate = Color(0xFF596579);

class DiscoveryPreferencesScreen extends ConsumerWidget {
  const DiscoveryPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(discoveryPreferencesProvider);

    return prefsState.when(
      data: (prefs) => _DiscoveryPreferencesForm(initial: prefs),
      loading: () => const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Discovery preferences'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(
                    message: 'Loading discovery preferences…',
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
                const AppRouteHeader(title: 'Discovery preferences'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load discovery preferences right now.',
                    onRetry: () => ref.invalidate(discoveryPreferencesProvider),
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

class _DiscoveryPreferencesForm extends ConsumerStatefulWidget {
  const _DiscoveryPreferencesForm({required this.initial});

  final DiscoveryPreferences initial;

  @override
  ConsumerState<_DiscoveryPreferencesForm> createState() =>
      _DiscoveryPreferencesFormState();
}

class _DiscoveryPreferencesFormState
    extends ConsumerState<_DiscoveryPreferencesForm> {
  final _formKey = GlobalKey<FormState>();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  late int? _maxDistanceKm;
  late Set<String> _selectedInterestedIn;
  late ProfileEditDealbreakers _dealbreakers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _minAgeController.text = widget.initial.minAge?.toString() ?? '';
    _maxAgeController.text = widget.initial.maxAge?.toString() ?? '';
    _maxDistanceKm = widget.initial.maxDistanceKm;
    _selectedInterestedIn = widget.initial.interestedIn.toSet();
    _dealbreakers = widget.initial.dealbreakers;
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
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
              _prefRose.withValues(
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
                  backgroundColor: _prefRose,
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
                label: Text(_isSaving ? 'Saving…' : 'Save preferences'),
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
                child: const AppRouteHeader(title: 'Discovery preferences'),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    0,
                    AppTheme.pagePadding,
                    AppTheme.bottomActionScrollPadding().bottom,
                  ),
                  children: [
                    _DiscoverySection(
                      icon: Icons.tune_rounded,
                      accentColor: _prefSky,
                      title: 'Age range',
                      description: 'Set the age window you want to discover.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _minAgeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Minimum age',
                                    hintText: '25',
                                  ),
                                  validator: _validatePositiveInteger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxAgeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Maximum age',
                                    hintText: '35',
                                  ),
                                  validator: (value) => _validateMaxAge(
                                    value,
                                    minAgeValue: _minAgeController.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _DiscoverySection(
                      icon: Icons.explore_outlined,
                      accentColor: _prefAmber,
                      title: 'Distance',
                      description: 'How far should we look for matches?',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _maxDistanceKm == null
                                      ? 'Distance not set'
                                      : 'Showing matches within',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (_maxDistanceKm != null)
                                Text(
                                  '${_distanceSliderValue.round()} km',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _prefAmber,
                                  ),
                                ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _prefAmber,
                              inactiveTrackColor: _prefAmber.withValues(
                                alpha: 0.18,
                              ),
                              thumbColor: _prefAmber,
                              overlayColor: _prefAmber.withValues(alpha: 0.12),
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
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _DiscoverySection(
                      icon: Icons.favorite_outline_rounded,
                      accentColor: _prefRose,
                      title: 'Interested in',
                      description: 'Who do you want to see in discover?',
                      child: _DiscoveryOptionGrid(
                        options: _genderOptions,
                        accentColor: _prefRose,
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
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _DiscoverySection(
                      icon: Icons.block_outlined,
                      accentColor: _prefSlate,
                      title: 'Dealbreakers',
                      description:
                          'Profiles that don\'t match these won\'t appear.',
                      child: _DealbreakersPanel(
                        dealbreakers: _dealbreakers,
                        onChanged: (value) {
                          setState(() {
                            _dealbreakers = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _DiscoverySection(
                      icon: Icons.verified_outlined,
                      accentColor: _prefMint,
                      title: 'Verified only',
                      description:
                          'Show only verified profiles. Not supported by the backend yet.',
                      child: _UnavailableControl(
                        label: 'Verified-only filter',
                        icon: Icons.verified_user_outlined,
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _DiscoverySection(
                      icon: Icons.travel_explore_outlined,
                      accentColor: _prefSky,
                      title: 'Travel mode',
                      description:
                          'Browse in a different location. Not supported by the backend yet.',
                      child: _UnavailableControl(
                        label: 'Travel mode',
                        icon: Icons.map_outlined,
                      ),
                    ),
                    SizedBox(height: AppTheme.compactSectionGap),
                    _DiscoverySection(
                      icon: Icons.thumb_down_alt_outlined,
                      accentColor: _prefSlate,
                      title: 'Show me less like this',
                      description:
                          'Feedback to tune recommendations. Not supported by the backend yet.',
                      child: _UnavailableControl(
                        label: 'Show me less like this',
                        icon: Icons.do_not_disturb_on_outlined,
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

    final messenger = ScaffoldMessenger.of(context);

    final preferences = DiscoveryPreferences(
      minAge: _parseOptionalInt(_minAgeController.text),
      maxAge: _parseOptionalInt(_maxAgeController.text),
      maxDistanceKm: _maxDistanceKm,
      interestedIn: _selectedInterestedIn.toList(growable: false),
      dealbreakers: _dealbreakers,
    );

    try {
      await ref.read(discoveryPreferencesControllerProvider).save(preferences);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on ApiError catch (error) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to save discovery preferences: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to save preferences right now.'),
          ),
        );
      }
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

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({
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
                _DiscoverySectionIconChip(icon: icon, color: accentColor),
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

class _DiscoverySectionIconChip extends StatelessWidget {
  const _DiscoverySectionIconChip({required this.icon, required this.color});

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

class _DiscoveryOptionGrid extends StatelessWidget {
  const _DiscoveryOptionGrid({
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

class _DealbreakersPanel extends StatelessWidget {
  const _DealbreakersPanel({
    required this.dealbreakers,
    required this.onChanged,
  });

  final ProfileEditDealbreakers dealbreakers;
  final ValueChanged<ProfileEditDealbreakers> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Column(
        children: [
          _DealbreakerTile(
            title: 'Smoking',
            options: _smokingOptions,
            selected: dealbreakers.acceptableSmoking.toSet(),
            onChanged: (value) {
              onChanged(
                ProfileEditDealbreakers(
                  acceptableSmoking: value.toList(growable: false),
                  acceptableDrinking: dealbreakers.acceptableDrinking,
                  acceptableKidsStance: dealbreakers.acceptableKidsStance,
                  acceptableLookingFor: dealbreakers.acceptableLookingFor,
                  acceptableEducation: dealbreakers.acceptableEducation,
                  minHeightCm: dealbreakers.minHeightCm,
                  maxHeightCm: dealbreakers.maxHeightCm,
                  maxAgeDifference: dealbreakers.maxAgeDifference,
                ),
              );
            },
          ),
          _DealbreakerTile(
            title: 'Drinking',
            options: _drinkingOptions,
            selected: dealbreakers.acceptableDrinking.toSet(),
            onChanged: (value) {
              onChanged(
                ProfileEditDealbreakers(
                  acceptableSmoking: dealbreakers.acceptableSmoking,
                  acceptableDrinking: value.toList(growable: false),
                  acceptableKidsStance: dealbreakers.acceptableKidsStance,
                  acceptableLookingFor: dealbreakers.acceptableLookingFor,
                  acceptableEducation: dealbreakers.acceptableEducation,
                  minHeightCm: dealbreakers.minHeightCm,
                  maxHeightCm: dealbreakers.maxHeightCm,
                  maxAgeDifference: dealbreakers.maxAgeDifference,
                ),
              );
            },
          ),
          _DealbreakerTile(
            title: 'Kids stance',
            options: _kidsStanceOptions,
            selected: dealbreakers.acceptableKidsStance.toSet(),
            onChanged: (value) {
              onChanged(
                ProfileEditDealbreakers(
                  acceptableSmoking: dealbreakers.acceptableSmoking,
                  acceptableDrinking: dealbreakers.acceptableDrinking,
                  acceptableKidsStance: value.toList(growable: false),
                  acceptableLookingFor: dealbreakers.acceptableLookingFor,
                  acceptableEducation: dealbreakers.acceptableEducation,
                  minHeightCm: dealbreakers.minHeightCm,
                  maxHeightCm: dealbreakers.maxHeightCm,
                  maxAgeDifference: dealbreakers.maxAgeDifference,
                ),
              );
            },
          ),
          _DealbreakerTile(
            title: 'Looking for',
            options: _lookingForOptions,
            selected: dealbreakers.acceptableLookingFor.toSet(),
            onChanged: (value) {
              onChanged(
                ProfileEditDealbreakers(
                  acceptableSmoking: dealbreakers.acceptableSmoking,
                  acceptableDrinking: dealbreakers.acceptableDrinking,
                  acceptableKidsStance: dealbreakers.acceptableKidsStance,
                  acceptableLookingFor: value.toList(growable: false),
                  acceptableEducation: dealbreakers.acceptableEducation,
                  minHeightCm: dealbreakers.minHeightCm,
                  maxHeightCm: dealbreakers.maxHeightCm,
                  maxAgeDifference: dealbreakers.maxAgeDifference,
                ),
              );
            },
          ),
          _DealbreakerTile(
            title: 'Education',
            options: _educationOptions,
            selected: dealbreakers.acceptableEducation.toSet(),
            onChanged: (value) {
              onChanged(
                ProfileEditDealbreakers(
                  acceptableSmoking: dealbreakers.acceptableSmoking,
                  acceptableDrinking: dealbreakers.acceptableDrinking,
                  acceptableKidsStance: dealbreakers.acceptableKidsStance,
                  acceptableLookingFor: dealbreakers.acceptableLookingFor,
                  acceptableEducation: value.toList(growable: false),
                  minHeightCm: dealbreakers.minHeightCm,
                  maxHeightCm: dealbreakers.maxHeightCm,
                  maxAgeDifference: dealbreakers.maxAgeDifference,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DealbreakerTile extends StatelessWidget {
  const _DealbreakerTile({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      iconColor: _prefSlate,
      collapsedIconColor: _prefSlate,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(
        selected.isEmpty ? 'No preference set' : '${selected.length} selected',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        _DiscoveryOptionGrid(
          options: options,
          accentColor: _prefSlate,
          selectedOptions: selected,
          onOptionToggled: (option, isSelected) {
            final updated = Set<String>.of(selected);
            if (isSelected) {
              updated.add(option);
            } else {
              updated.remove(option);
            }
            onChanged(updated);
          },
        ),
      ],
    );
  }
}

class _UnavailableControl extends StatelessWidget {
  const _UnavailableControl({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _DiscoveryStatusPill(
              label: 'Unavailable',
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryStatusPill extends StatelessWidget {
  const _DiscoveryStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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

int? _parseOptionalInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return int.tryParse(trimmed);
}

const List<String> _genderOptions = <String>[
  'FEMALE',
  'MALE',
  'NON_BINARY',
  'OTHER',
];

const List<String> _smokingOptions = <String>[
  'NEVER',
  'SOCIALLY',
  'REGULARLY',
  'QUITTING',
];

const List<String> _drinkingOptions = <String>[
  'NEVER',
  'SOCIALLY',
  'REGULARLY',
  'QUITTING',
];

const List<String> _kidsStanceOptions = <String>[
  'WANT_KIDS',
  'OPEN',
  'SOMEDAY',
  'DO_NOT_WANT',
];

const List<String> _lookingForOptions = <String>[
  'CASUAL',
  'LONG_TERM',
  'MARRIAGE',
  'NOT_SURE',
];

const List<String> _educationOptions = <String>[
  'HIGH_SCHOOL',
  'BACHELORS',
  'MASTERS',
  'PHD',
  'OTHER',
];
