import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/profile_update_request.dart';
import '../../models/user_detail.dart';
import '../../shared/formatting/display_text.dart';
import '../location/location_completion_screen.dart';
import 'profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.initialDetail});

  final UserDetail initialDetail;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bioController;
  late final TextEditingController _genderController;
  late final TextEditingController _interestedInController;
  late final TextEditingController _maxDistanceController;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;
  late final TextEditingController _heightController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.initialDetail.bio);
    _genderController = TextEditingController(
      text: formatDisplayLabel(widget.initialDetail.gender, fallback: ''),
    );
    _interestedInController = TextEditingController(
      text: formatDisplayLabelList(
        widget.initialDetail.interestedIn,
        fallback: '',
      ),
    );
    _maxDistanceController = TextEditingController(
      text: widget.initialDetail.maxDistanceKm > 0
          ? widget.initialDetail.maxDistanceKm.toString()
          : '',
    );
    _minAgeController = TextEditingController();
    _maxAgeController = TextEditingController();
    _heightController = TextEditingController();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _genderController.dispose();
    _interestedInController.dispose();
    _maxDistanceController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit your profile')),
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
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Show people a version of you that feels true.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Update the details you want to share, and leave anything blank if you'd rather skip it for now.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText:
                      'Share a little about your vibe, interests, or ideal first date',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  hintText: 'Female, Male, Non-binary, Other',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  if (!_allowedGenderValues.contains(_normalizeGender(value))) {
                    return 'Choose Female, Male, Non-binary, or Other.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestedInController,
                decoration: const InputDecoration(
                  labelText: 'Interested in',
                  hintText: 'Female, Male, Non-binary, Other',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return null;
                  }

                  final interests = _parseInterestedIn(value)
                      .where((entry) => entry.trim().isNotEmpty)
                      .toList(growable: false);
                  if (interests.isEmpty) {
                    return null;
                  }

                  if (interests.any(
                    (entry) => !_allowedGenderValues.contains(entry),
                  )) {
                    return 'Choose Female, Male, Non-binary, or Other.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxDistanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum distance (km)',
                  hintText: '50',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final distance = int.tryParse(value.trim());
                  if (distance == null || distance <= 0) {
                    return 'Please enter a valid maximum distance.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum preferred age',
                  hintText: '25',
                ),
                validator: _validatePositiveInteger,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum preferred age',
                  hintText: '35',
                ),
                validator: _validatePositiveInteger,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: '172',
                ),
                validator: _validatePositiveInteger,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Choose location'),
                  subtitle: Text(
                    widget.initialDetail.approximateLocation.trim().isEmpty
                        ? 'Add the area where you want to meet people.'
                        : 'Currently showing people near ${widget.initialDetail.approximateLocation}.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const LocationCompletionScreen(),
                      ),
                    );
                  },
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
      gender: _normalizedOrNull(_genderController.text),
      interestedIn: _interestedInOrNull(_interestedInController.text),
      maxDistanceKm: _parseOptionalInt(_maxDistanceController.text),
      minAge: _parseOptionalInt(_minAgeController.text),
      maxAge: _parseOptionalInt(_maxAgeController.text),
      heightCm: _parseOptionalInt(_heightController.text),
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

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _normalizedOrNull(String value) {
  final normalized = _normalizeGender(value);
  return normalized.isEmpty ? null : normalized;
}

List<String>? _interestedInOrNull(String value) {
  final interestedIn = _parseInterestedIn(value);
  return interestedIn.isEmpty ? null : interestedIn;
}

int? _parseOptionalInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return int.tryParse(trimmed);
}

List<String> _parseInterestedIn(String? value) {
  return (value ?? '')
      .split(',')
      .map(_normalizeGender)
      .where((entry) => entry.isNotEmpty)
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

const Set<String> _allowedGenderValues = <String>{
  'FEMALE',
  'MALE',
  'NON_BINARY',
  'OTHER',
};
