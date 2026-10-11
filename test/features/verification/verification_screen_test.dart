import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/verification/verification_screen.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/models/verification_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  Finder verificationScrollable() {
    return find
        .descendant(
          of: find.byType(VerificationScreen),
          matching: find.byType(Scrollable),
        )
        .first;
  }

  testWidgets('keeps the main chrome user-facing and quarantines test code', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeVerificationApiClient(
      startResult: const VerificationStartResult(
        userId: '11111111-1111-1111-1111-111111111111',
        method: 'EMAIL',
        contact: 'dana@example.com',
        devVerificationCode: '246810',
      ),
      confirmResult: const VerificationConfirmationResult(
        verified: true,
        verifiedAt: null,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(home: VerificationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification'), findsWidgets);
    expect(find.text('Verify your email or phone'), findsNothing);
    expect(find.text('Start verification'), findsOneWidget);
    expect(
      find.text(
        'Use the backend-supported email or phone flow. In development, the generated code is surfaced so you can finish the flow without leaving the app.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Send a code to your email or phone, then enter it here to confirm it\'s yours.',
      ),
      findsNothing,
    );
    expect(find.text('Debug helpers stay separate'), findsNothing);
    expect(find.textContaining('Resend'), findsNothing);
    expect(find.textContaining('cooldown'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Send verification code'),
      250,
      scrollable: verificationScrollable(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Send verification code'),
    );
    await tester.pumpAndSettle();

    expect(apiClient.startedContact, isNull);
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'dana@example.com');
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Send verification code'),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Test code'),
      250,
      scrollable: verificationScrollable(),
    );
    await tester.pumpAndSettle();

    expect(apiClient.startedMethod, 'EMAIL');
    expect(apiClient.startedContact, 'dana@example.com');
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Developer only'), findsOneWidget);
    expect(find.text('Test code'), findsOneWidget);
    expect(find.widgetWithText(SelectableText, '246810'), findsOneWidget);
  });

  const startResult = VerificationStartResult(
    userId: '11111111-1111-1111-1111-111111111111',
    method: 'EMAIL',
    contact: 'dana@example.com',
    devVerificationCode: '246810',
  );
  const confirmResult = VerificationConfirmationResult(
    verified: true,
    verifiedAt: null,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    _FakeVerificationApiClient apiClient,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(home: VerificationScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendCode(WidgetTester tester, String buttonLabel) async {
    await tester.enterText(find.byType(TextField).first, 'dana@example.com');
    final button = find.widgetWithText(FilledButton, buttonLabel);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> confirmCode(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Confirm verification');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String buttonLabel) {
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, buttonLabel),
    );
    return button.onPressed != null;
  }

  testWidgets('resend is held for 60 seconds after a code is sent', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeVerificationApiClient(
      startResult: startResult,
      confirmResult: confirmResult,
    );
    await pumpScreen(tester, apiClient);

    await sendCode(tester, 'Send verification code');

    expect(apiClient.startCalls, 1);
    expect(isEnabled(tester, 'Resend in 60 s'), isFalse);

    await tester.pump(const Duration(seconds: 59));
    expect(isEnabled(tester, 'Resend in 1 s'), isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(isEnabled(tester, 'Resend code'), isTrue);
  });

  testWidgets('"already sent" is shown in the screen and holds resend', (
    WidgetTester tester,
  ) async {
    const message =
        'Verification code already sent. Please wait before '
        'retrying.';
    final apiClient = _FakeVerificationApiClient(
      startResult: startResult,
      confirmResult: confirmResult,
      startError: const ApiError(
        message: message,
        code: 'BAD_REQUEST',
        statusCode: 400,
      ),
    );
    await pumpScreen(tester, apiClient);

    await sendCode(tester, 'Send verification code');

    expect(find.text(message), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(isEnabled(tester, 'Resend in 60 s'), isFalse);

    await tester.pump(const Duration(seconds: 60));
    expect(isEnabled(tester, 'Send verification code'), isTrue);
  });

  for (final message in const [
    'Incorrect code.',
    'Code expired. Please try again.',
  ]) {
    testWidgets('confirm 400 "$message" is shown and can be retried', (
      WidgetTester tester,
    ) async {
      final apiClient = _FakeVerificationApiClient(
        startResult: startResult,
        confirmResult: confirmResult,
        confirmError: ApiError(
          message: message,
          code: 'BAD_REQUEST',
          statusCode: 400,
        ),
      );
      await pumpScreen(tester, apiClient);
      await sendCode(tester, 'Send verification code');

      await confirmCode(tester);

      expect(apiClient.confirmCalls, 1);
      expect(find.text(message), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(isEnabled(tester, 'Confirm verification'), isTrue);

      // Let the resend countdown finish so no timer outlives the test.
      await tester.pump(const Duration(seconds: 60));
    });
  }

  testWidgets('confirm 429 shows the message and disables confirm', (
    WidgetTester tester,
  ) async {
    const message = 'Too many attempts. Please try again later.';
    final apiClient = _FakeVerificationApiClient(
      startResult: startResult,
      confirmResult: confirmResult,
      confirmError: const ApiError(
        message: message,
        code: 'RATE_LIMITED',
        statusCode: 429,
      ),
    );
    await pumpScreen(tester, apiClient);
    await sendCode(tester, 'Send verification code');

    await confirmCode(tester);

    expect(find.text(message), findsOneWidget);
    expect(isEnabled(tester, 'Confirm verification'), isFalse);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Confirm verification'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(apiClient.confirmCalls, 1);

    await tester.pump(const Duration(seconds: 60));
  });

  testWidgets('shows a phone icon when the verification method is phone', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeVerificationApiClient(
      startResult: const VerificationStartResult(
        userId: '11111111-1111-1111-1111-111111111111',
        method: 'PHONE',
        contact: '+1 555 555 5555',
        devVerificationCode: '135790',
      ),
      confirmResult: const VerificationConfirmationResult(
        verified: true,
        verifiedAt: null,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(home: VerificationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '+1 555 555 5555');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Send verification code'),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.phone_outlined),
      250,
      scrollable: verificationScrollable(),
    );
    await tester.pumpAndSettle();

    expect(apiClient.startedMethod, 'PHONE');
    expect(apiClient.startedContact, '+1 555 555 5555');
    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
  });
}

class _FakeVerificationApiClient extends ApiClient {
  _FakeVerificationApiClient({
    required this.startResult,
    required this.confirmResult,
    this.startError,
    this.confirmError,
  }) : super(dio: Dio());

  final ApiError? startError;
  final ApiError? confirmError;
  int startCalls = 0;
  int confirmCalls = 0;

  final VerificationStartResult startResult;
  final VerificationConfirmationResult confirmResult;
  String? startedMethod;
  String? startedContact;
  String? confirmedCode;

  @override
  Future<VerificationStartResult> startVerification({
    required String userId,
    required String method,
    required String contact,
  }) async {
    startCalls++;
    if (startError case final error?) {
      throw error;
    }
    startedMethod = method;
    startedContact = contact;
    return startResult;
  }

  @override
  Future<VerificationConfirmationResult> confirmVerification({
    required String userId,
    required String verificationCode,
  }) async {
    confirmCalls++;
    if (confirmError case final error?) {
      throw error;
    }
    confirmedCode = verificationCode;
    return confirmResult;
  }
}
