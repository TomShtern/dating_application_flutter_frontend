import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/stats/achievements_screen.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  testWidgets(
    'shows compact visual progress for overall and in-progress achievements',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            achievementsProvider.overrideWith(
              (ref) async => const [
                AchievementSummary(
                  title: 'Early Bird',
                  subtitle: 'Opened the app before 8am',
                  isUnlocked: true,
                ),
                AchievementSummary(
                  title: 'Conversation Starter',
                  subtitle: 'Kick off more chats this week',
                  progress: '3/5 conversations started',
                  isUnlocked: false,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(currentUser: currentUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Achievements'), findsOneWidget);
      expect(find.text("Dana's achievement progress"), findsOneWidget);
      expect(find.text('Overall progress'), findsOneWidget);
      expect(find.text('1 of 2 unlocked'), findsOneWidget);
      expect(find.text('1 still building'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(
        find.text('3/5 conversations started', skipOffstage: false),
        findsNWidgets(2),
      );

      final overviewProgress = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('achievements-overview-progress')),
      );
      expect(overviewProgress.value, 0.5);

      final itemProgress = tester.widget<LinearProgressIndicator>(
        find.byKey(
          const ValueKey('achievement-progress-Conversation Starter'),
          skipOffstage: false,
        ),
      );
      expect(itemProgress.value, 0.6);
    },
  );
}
