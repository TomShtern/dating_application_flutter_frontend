import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/location_metadata.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../theme/app_theme.dart';
import 'location_provider.dart';

const _locationSky = Color(0xFF188DC8);
const _locationMint = Color(0xFF16A871);
const _locationSlate = Color(0xFF596579);

class LocationCompletionScreen extends ConsumerStatefulWidget {
  const LocationCompletionScreen({super.key});

  @override
  ConsumerState<LocationCompletionScreen> createState() =>
      _LocationCompletionScreenState();
}

class _LocationCompletionScreenState
    extends ConsumerState<LocationCompletionScreen> {
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  late final ProviderSubscription<AsyncValue<List<LocationCountry>>>
  _countriesSubscription;
  bool _allowApproximate = true;
  bool _saving = false;
  String? _countryCode;
  String? _selectedCityLabel;

  @override
  void initState() {
    super.initState();
    _countriesSubscription = ref
        .listenManual<AsyncValue<List<LocationCountry>>>(
          locationCountriesProvider,
          (previous, next) {
            final countries = next.maybeWhen(
              data: (countries) => countries,
              orElse: () => null,
            );
            if (countries == null || countries.isEmpty) {
              return;
            }

            final availableCountries = countries
                .where((c) => c.available)
                .toList();
            final nextCountryCode = _resolveInitialCountryCode(
              availableCountries,
            );
            if (nextCountryCode != _countryCode) {
              setState(() {
                _countryCode = nextCountryCode;
                _selectedCityLabel = null;
              });
            }
          },
          fireImmediately: true,
        );
  }

  @override
  void dispose() {
    _countriesSubscription.close();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countriesState = ref.watch(locationCountriesProvider);
    final citySuggestionsState = ref.watch(
      locationCitySuggestionsProvider(
        LocationCitySearchQuery(
          countryCode: _countryCode ?? '',
          query: _cityController.text,
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            8,
            AppTheme.pagePadding,
            AppTheme.pagePadding,
          ),
          child: countriesState.when(
            data: (countries) {
              final availableCountries = countries
                  .where((country) => country.available)
                  .toList(growable: false);
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              final isDark = theme.brightness == Brightness.dark;

              return ListView(
                children: [
                  const AppRouteHeader(title: 'Location'),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: AppTheme.surfaceDecoration(
                      context,
                      color: Color.alphaBlend(
                        _locationSky.withValues(alpha: isDark ? 0.08 : 0.03),
                        colorScheme.surfaceContainerLow,
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
                              const _LocationLeadChip(
                                icon: Icons.location_on_outlined,
                                color: _locationSky,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Match area',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Choose the country and city we should use for nearby matches.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.compactCardGap),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String?>(_countryCode),
                            initialValue: _countryCode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                            ),
                            items: availableCountries
                                .map(
                                  (country) => DropdownMenuItem<String>(
                                    value: country.code,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const _CountryFlagIcon(),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            country.name,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              setState(() {
                                _countryCode = value;
                                _selectedCityLabel = null;
                              });
                            },
                          ),
                          const SizedBox(height: AppTheme.compactCardGap),
                          TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              hintText: 'Start typing your city',
                            ),
                            onChanged: (_) {
                              setState(() {
                                _selectedCityLabel = null;
                              });
                            },
                          ),
                          const SizedBox(height: AppTheme.compactCardGap),
                          TextField(
                            controller: _zipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP code (optional)',
                            ),
                          ),
                          const SizedBox(height: 4),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: _locationSlate.withValues(
                                alpha: isDark ? 0.12 : 0.04,
                              ),
                              borderRadius: AppTheme.cardRadius,
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              dense: true,
                              value: _allowApproximate,
                              title: const Text(
                                'Use the closest match if needed',
                              ),
                              subtitle: const Text(
                                "If we can't resolve the exact city or ZIP, we'll use the nearest available area.",
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _allowApproximate = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: AppTheme.sectionGap),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _locationSky,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _saving
                                  ? null
                                  : () => _handleSave(context),
                              icon: _saving
                                  ? SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              colorScheme.onPrimary,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.location_on_outlined),
                              label: Text(
                                _saving ? 'Saving…' : 'Save location',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.cardGap),
                          Text(
                            'You can change this anytime.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_selectedCityLabel != null) ...[
                            const SizedBox(height: AppTheme.cardGap),
                            _SelectedCityCard(cityLabel: _selectedCityLabel!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  DecoratedBox(
                    decoration: AppTheme.surfaceDecoration(
                      context,
                      color: Color.alphaBlend(
                        _locationSlate.withValues(alpha: isDark ? 0.10 : 0.03),
                        colorScheme.surfaceContainerLow,
                      ),
                    ),
                    child: Padding(
                      padding: AppTheme.sectionPadding(compact: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          citySuggestionsState.when(
                            data: (cities) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppGroupLabel(
                                    title: 'Suggested cities',
                                    accentColor: _locationSky,
                                    countText: '${cities.length}',
                                  ),
                                  const SizedBox(height: AppTheme.cardGap),
                                  if (cities.isEmpty)
                                    const _SuggestionStateNotice(
                                      icon: Icons.search_rounded,
                                      title: 'Start typing a city',
                                      message:
                                          'Type at least two letters to see the closest matches.',
                                      color: _locationSky,
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (final city in cities)
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  AppTheme.panelRadius,
                                              onTap: () {
                                                setState(() {
                                                  _cityController.text =
                                                      city.name;
                                                  _selectedCityLabel =
                                                      _cityDisplayLabel(city);
                                                });
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    const _LocationLeadChip(
                                                      icon:
                                                          Icons.place_outlined,
                                                      color: _locationSky,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            city.name,
                                                            style: theme
                                                                .textTheme
                                                                .titleSmall,
                                                          ),
                                                          if (city
                                                              .district
                                                              .isNotEmpty) ...[
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              city.district,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color: colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      size: 20,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: _SuggestionStateNotice(
                                icon: Icons.sync_rounded,
                                title: 'Loading suggestions',
                                message:
                                    'Checking nearby city matches for you.',
                                color: _locationSky,
                                showSpinner: true,
                              ),
                            ),
                            error: (_, _) => const _SuggestionStateNotice(
                              icon: Icons.error_outline_rounded,
                              title: 'Suggestions unavailable',
                              message:
                                  "We can't load city suggestions right now.",
                              color: _locationSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Location'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(
                    message: 'Loading location options…',
                  ),
                ),
              ],
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRouteHeader(title: 'Location'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load location options right now.',
                    onRetry: () => ref.invalidate(locationCountriesProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveInitialCountryCode(List<LocationCountry> countries) {
    for (final country in countries) {
      if (country.defaultSelection) {
        return country.code;
      }
    }

    if (countries.isEmpty) {
      return null;
    }

    return countries.first.code;
  }

  Future<void> _handleSave(BuildContext context) async {
    final countryCode = _countryCode;
    final cityName = _cityController.text.trim();
    final zipCode = _zipController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (countryCode == null || countryCode.isEmpty || cityName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Choose a country and city first.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final resolved = await ref
          .read(locationControllerProvider)
          .resolveAndSaveProfileLocation(
            countryCode: countryCode,
            cityName: cityName,
            zipCode: zipCode.isEmpty ? null : zipCode,
            allowApproximate: _allowApproximate,
          );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Location updated to ${resolved.label}.')),
      );
      navigator.pop(resolved);
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

String _cityDisplayLabel(LocationCity city) {
  if (city.district.trim().isEmpty) {
    return city.name;
  }

  return '${city.name}, ${city.district}';
}

class _LocationLeadChip extends StatelessWidget {
  const _LocationLeadChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _SuggestionStateNotice extends StatelessWidget {
  const _SuggestionStateNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.showSpinner = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: AppTheme.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LocationLeadChip(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountryFlagIcon extends StatelessWidget {
  const _CountryFlagIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _locationSky.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.20 : 0.10,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: _locationSky.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Icon(Icons.flag_outlined, size: 18, color: _locationSky),
      ),
    );
  }
}

class _SelectedCityCard extends StatelessWidget {
  const _SelectedCityCard({required this.cityLabel});

  final String cityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _locationMint.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: _locationMint.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _locationMint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected city',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _locationMint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(cityLabel, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
