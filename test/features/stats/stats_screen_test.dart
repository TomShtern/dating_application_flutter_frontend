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
    expect(find.text('Likes Sent'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.byTooltip('View achievements'));
    await tester.pumpAndSettle();

    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.text('Early Bird'), findsOneWidget);
  });
}
