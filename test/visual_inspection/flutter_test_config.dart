import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/visual_review_font_loader.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ensureVisualReviewFontsLoaded();
  await testMain();
}
