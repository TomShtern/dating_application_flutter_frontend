import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/profile_update_request.dart';
import '../../models/user_detail.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.initialDetail.bio);
    _genderController = TextEditingController(
      text: widget.initialDetail.gender,
    );
    _interestedInController = TextEditingController(
      text: widget.initialDetail.interestedIn.join(', '),
    );
    _maxDistanceController = TextEditingController(
      text: widget.initialDetail.maxDistanceKm > 0
          ? widget.initialDetail.maxDistanceKm.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _genderController.dispose();
    _interestedInController.dispose();
    _maxDistanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Update the profile details currently surfaced in the mobile app. Leave a field blank if you want it to stay unspecified.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell people a bit about yourself',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  hintText: 'FEMALE, MALE, NON_BINARY, OTHER',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  if (!_allowedGenderValues.contains(_normalizeGender(value))) {
                    return 'Use FEMALE, MALE, NON_BINARY, or OTHER.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestedInController,
                decoration: const InputDecoration(
                  labelText: 'Interested in',
                  hintText: 'MALE, FEMALE, NON_BINARY, OTHER',
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
                    return 'Use MALE, FEMALE, NON_BINARY, or OTHER.';
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                child: Text(_isSaving ? 'Saving…' : 'Save changes'),
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
      bio: _bioController.text.trim(),
      gender: _normalizeGender(_genderController.text),
      interestedIn: _parseInterestedIn(_interestedInController.text),
      maxDistanceKm: int.tryParse(_maxDistanceController.text.trim()) ?? 0,
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

List<String> _parseInterestedIn(String? value) {
  return (value ?? '')
      .split(',')
      .map(_normalizeGender)
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String _normalizeGender(String value) => value.trim().toUpperCase();

const Set<String> _allowedGenderValues = <String>{
  'FEMALE',
  'MALE',
  'NON_BINARY',
  'OTHER',
};
