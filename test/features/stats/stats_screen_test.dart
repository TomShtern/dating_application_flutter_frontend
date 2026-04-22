import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/stats/achievements_screen.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/features/stats/stats_screen.dart';
import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/user_stats.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  Finder statsScrollable() {
    return find.descendant(
      of: find.byType(StatsScreen),
      matching: find.byType(Scrollable),
    );
  }

  Finder achievementsScrollable() {
    return find.descendant(
      of: find.byType(AchievementsScreen),
      matching: find.byType(Scrollable),
    );
  }

  testWidgets('renders stats and opens the achievements screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(
            (ref) async => const UserStats(
              items: [
                UserStatItem(label: 'Likes Sent', value: '12'),
                UserStatItem(label: 'Matches', value: '4'),
              ],
            ),
          ),
          achievementsProvider.overrideWith(
            (ref) async => const [
              AchievementSummary(
                title: 'Early Bird',
                subtitle: 'Opened the app before 8am',
                isUnlocked: true,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: StatsScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Stats'), findsOneWidget);
    expect(find.text('Momentum for Dana'), findsOneWidget);
    expect(find.text('2 highlights'), findsOneWidget);
    expect(find.text('Active profile'), findsOneWidget);
    expect(find.text('Why this snapshot matters'), findsNothing);
    expect(find.text("Dana's momentum at a glance"), findsNothing);

    expect(find.text('2 tracked stats'), findsNothing);
    expect(find.text('What these stats show'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Likes Sent'),
      200,
      scrollable: statsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Likes Sent'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Momentum right now'), findsNothing);
    expect(find.text('Latest backend snapshot'), findsNothing);

    await tester.tap(find.byTooltip('View achievements'));
    await tester.pumpAndSettle();

    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.text("Dana's achievement progress"), findsOneWidget);
    expect(find.text('1 unlocked'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Early Bird'),
      200,
      scrollable: achievementsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Early Bird'), findsOneWidget);
  });
}
