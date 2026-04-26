import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/location_metadata.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../theme/app_theme.dart';
import 'location_provider.dart';

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
      appBar: AppBar(title: const Text('Choose your location')),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding(),
          child: countriesState.when(
            data: (countries) {
              final availableCountries = countries
                  .where((country) => country.available)
                  .toList(growable: false);

              return ListView(
                children: [
                  DecoratedBox(
                    decoration: AppTheme.surfaceDecoration(context),
                    child: Padding(
                      padding: AppTheme.sectionPadding(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your area',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Choose the country and city you want us to use for nearby matches.',
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String?>(_countryCode),
                            initialValue: _countryCode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Country',
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
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          TextField(
                            controller: _zipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP code (optional)',
                            ),
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _handleSave(context),
                              icon: const Icon(Icons.location_on_outlined),
                              label: Text(
                                _saving ? 'Saving…' : 'Use this location',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can change this anytime.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (_selectedCityLabel != null) ...[
                            const SizedBox(height: 10),
                            _SelectedCityCard(cityLabel: _selectedCityLabel!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  DecoratedBox(
                    decoration: AppTheme.surfaceDecoration(context),
                    child: Padding(
                      padding: AppTheme.sectionPadding(compact: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggested cities',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          citySuggestionsState.when(
                            data: (cities) {
                              if (cities.isEmpty) {
                                return const Text(
                                  'Type at least two letters for city suggestions.',
                                );
                              }
                              return Column(
                                children: cities
                                    .map(
                                      (city) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(city.name),
                                        subtitle: city.district.isEmpty
                                            ? null
                                            : Text(city.district),
                                        trailing: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _cityController.text = city.name;
                                            _selectedCityLabel =
                                                _cityDisplayLabel(city);
                                          });
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, _) => const Text(
                              "We can't load city suggestions right now.",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppAsyncState.loading(
              message: 'Loading location options…',
            ),
            error: (error, _) => AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load location options right now.',
              onRetry: () => ref.invalidate(locationCountriesProvider),
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

class _CountryFlagIcon extends StatelessWidget {
  const _CountryFlagIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Icon(
          Icons.flag_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
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
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: AppTheme.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected city', style: theme.textTheme.labelLarge),
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
