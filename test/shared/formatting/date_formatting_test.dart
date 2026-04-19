import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/formatting/date_formatting.dart';

void main() {
  test('formats a local timestamp for list and thread surfaces', () {
    final formatted = formatDateTimeStamp(DateTime(2026, 4, 18, 14, 20));

    expect(formatted, '2026-04-18 14:20');
  });

  test('formats a short local date for match summaries', () {
    final formatted = formatShortDate(DateTime(2026, 4, 18, 14, 20));

    expect(formatted, '2026-04-18');
  });
}
