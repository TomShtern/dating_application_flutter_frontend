import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/profile_presentation_context.dart';

void main() {
  test('fromJson parses the Stage B presentation context shape', () {
    final context = ProfilePresentationContext.fromJson({
      'viewerUserId': 'viewer-1',
      'targetUserId': 'target-1',
      'summary':
          'Shown because this profile is nearby and overlaps with your preferences.',
      'reasonTags': ['shared_interests', 'nearby'],
      'details': [
        'You both list Hiking and Coffee as interests.',
        'This profile is within your preferred distance.',
      ],
      'generatedAt': '2026-05-08T10:15:00Z',
    });

    expect(context.viewerUserId, 'viewer-1');
    expect(context.targetUserId, 'target-1');
    expect(context.reasonTags, ['shared_interests', 'nearby']);
    expect(context.details, hasLength(2));
    expect(context.generatedAt, '2026-05-08T10:15:00Z');
  });
}
