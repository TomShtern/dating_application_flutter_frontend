import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/report_result.dart';

void main() {
  test('reads autoFlagged from the report response', () {
    final result = ReportResult.fromJson(const {
      'success': true,
      'autoFlagged': true,
      'autoBanned': true,
      'errorMessage': null,
      'blockedByReporter': false,
    });

    expect(result.success, isTrue);
    expect(result.autoFlagged, isTrue);
    expect(result.blockedByReporter, isFalse);
    expect(result.errorMessage, isNull);
  });

  test('prefers autoFlagged over the deprecated autoBanned alias', () {
    final result = ReportResult.fromJson(const {
      'success': true,
      'autoFlagged': false,
      'autoBanned': true,
    });

    expect(result.autoFlagged, isFalse);
  });

  test('falls back to autoBanned for a backend without autoFlagged', () {
    final result = ReportResult.fromJson(const {
      'success': true,
      'autoBanned': true,
      'blockedByReporter': true,
    });

    expect(result.autoFlagged, isTrue);
    expect(result.blockedByReporter, isTrue);
  });

  test('treats missing flags as false', () {
    final result = ReportResult.fromJson(const {'success': true});

    expect(result.autoFlagged, isFalse);
    expect(result.blockedByReporter, isFalse);
  });
}
