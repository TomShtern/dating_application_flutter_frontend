import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
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

    expect(find.widgetWithText(AppBar, 'Verification'), findsOneWidget);
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
    expect(find.text('How it works'), findsNothing);
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

    await tester.enterText(find.byType(TextField).first, 'dana@example.com');
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
    expect(find.text('Developer only'), findsOneWidget);
    expect(find.text('Test code'), findsOneWidget);
    expect(find.widgetWithText(SelectableText, '246810'), findsOneWidget);
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

    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    expect(find.text('Phone'), findsWidgets);
  });
}

class _FakeVerificationApiClient extends ApiClient {
  _FakeVerificationApiClient({
    required this.startResult,
    required this.confirmResult,
  }) : super(dio: Dio());

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
    startedMethod = method;
    startedContact = contact;
    return startResult;
  }

  @override
  Future<VerificationConfirmationResult> confirmVerification({
    required String userId,
    required String verificationCode,
  }) async {
    confirmedCode = verificationCode;
    return confirmResult;
  }
}
