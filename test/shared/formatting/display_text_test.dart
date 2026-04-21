import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/formatting/display_text.dart';

void main() {
  group('display text', () {
    test('formats enum-like status labels for UI display', () {
      expect(formatDisplayLabel('ACTIVE'), 'Active');
      expect(formatDisplayLabel('NON_BINARY'), 'Non-binary');
    });

    test('formats preference lists for UI display', () {
      expect(formatDisplayLabelList(['FEMALE', 'MALE']), 'Female, Male');
    });

    test('returns a fallback for empty labels', () {
      expect(formatDisplayLabel(''), 'Not specified');
      expect(formatDisplayLabelList(const []), 'Not specified');
    });
  });
}
