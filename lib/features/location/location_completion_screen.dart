import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/location_metadata.dart';
import '../../shared/widgets/app_async_state.dart';
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
          padding: const EdgeInsets.all(24),
          child: countriesState.when(
            data: (countries) {
              final availableCountries = countries
                  .where((country) => country.available)
                  .toList(growable: false);

              return ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                        _CountryCodeBadge(code: country.code),
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
                            Chip(
                              label: Text('Using city: $_selectedCityLabel'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                            _selectedCityLabel = city.name;
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

class _CountryCodeBadge extends StatelessWidget {
  const _CountryCodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          code,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
