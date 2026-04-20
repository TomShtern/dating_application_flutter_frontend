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
  bool _allowApproximate = true;
  bool _saving = false;
  String? _countryCode;
  String? _selectedCityLabel;

  @override
  void dispose() {
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
      appBar: AppBar(title: const Text('Complete your location')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: countriesState.when(
            data: (countries) {
              final availableCountries = countries
                  .where((country) => country.available)
                  .toList(growable: false);
              final selectedCountry = _resolveSelectedCountry(
                availableCountries,
              );

              return ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Improve discovery with a real location',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pick a country, search for your city, and let the backend resolve the best available location for recommendations.',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedCountry?.code,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                            ),
                            items: availableCountries
                                .map(
                                  (country) => DropdownMenuItem<String>(
                                    value: country.code,
                                    child: Text(
                                      '${country.flagEmoji} ${country.name}',
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          TextField(
                            controller: _zipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP code (optional)',
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _allowApproximate,
                            title: const Text('Allow approximate resolution'),
                            subtitle: const Text(
                              'Use a nearby match if the exact city/ZIP combo cannot be resolved.',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _allowApproximate = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _handleSave(context),
                            icon: const Icon(Icons.location_on_outlined),
                            label: Text(_saving ? 'Saving…' : 'Save location'),
                          ),
                          if (_selectedCityLabel != null) ...[
                            const SizedBox(height: 12),
                            Chip(
                              label: Text('Selected city: $_selectedCityLabel'),
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
                            'City suggestions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          citySuggestionsState.when(
                            data: (cities) {
                              if (cities.isEmpty) {
                                return const Text(
                                  'Type at least two characters to get suggestions.',
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
                              'City suggestions are unavailable right now.',
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

  LocationCountry? _resolveSelectedCountry(List<LocationCountry> countries) {
    if (_countryCode != null) {
      return countries
          .where((country) => country.code == _countryCode)
          .firstOrNull;
    }

    final defaultCountry = countries
        .where((country) => country.defaultSelection)
        .firstOrNull;
    _countryCode =
        defaultCountry?.code ??
        (countries.isNotEmpty ? countries.first.code : null);
    return countries
        .where((country) => country.code == _countryCode)
        .firstOrNull;
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
        SnackBar(content: Text('Location saved as ${resolved.label}.')),
      );
      navigator.pop();
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
