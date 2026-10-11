import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/pace_preferences.dart';

void main() {
  const complete = PacePreferences(
    messagingFrequency: 'OFTEN',
    timeToFirstDate: 'FEW_DAYS',
    communicationStyle: 'TEXT_ONLY',
    depthPreference: 'DEEP_CHAT',
  );

  test('reads the backend object and writes it back unchanged', () {
    final json = complete.toJson();

    expect(json, {
      'messagingFrequency': 'OFTEN',
      'timeToFirstDate': 'FEW_DAYS',
      'communicationStyle': 'TEXT_ONLY',
      'depthPreference': 'DEEP_CHAT',
    });
    expect(PacePreferences.fromJson(json), complete);
  });

  test('anything that is not an object reads as blank', () {
    expect(PacePreferences.fromJson(null), PacePreferences.blank);
    expect(PacePreferences.fromJson('OFTEN'), PacePreferences.blank);
    expect(PacePreferences.fromJson(const <String>[]), PacePreferences.blank);
  });

  test('empty strings count as unanswered', () {
    final pace = PacePreferences.fromJson(const {
      'messagingFrequency': ' ',
      'timeToFirstDate': 'FEW_DAYS',
    });

    expect(pace.messagingFrequency, isNull);
    expect(pace.timeToFirstDate, 'FEW_DAYS');
  });

  test('only a fully answered object is complete', () {
    expect(complete.isComplete, isTrue);
    expect(PacePreferences.blank.isComplete, isFalse);
    expect(
      const PacePreferences(messagingFrequency: 'OFTEN').isComplete,
      isFalse,
    );
  });

  test('every question offers the options the backend accepts', () {
    expect(paceQuestions, hasLength(4));
    for (final question in paceQuestions) {
      expect(question.options, isNotEmpty);
      for (final value in question.options.keys) {
        final answered = question.write(PacePreferences.blank, value);
        expect(question.read(answered), value);
      }
    }
  });
}
