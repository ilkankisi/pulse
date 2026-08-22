import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import '../lib/features/pulse/presentation/bookmarks_page.dart';

import '../lib/features/pulse/presentation/notifications_page.dart';

void main() {
  testWidgets('notifications page renders empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),

        home: const NotificationsPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text('Bildirimler'), findsOneWidget);
    expect(find.text('Henüz bildirimin yok'), findsOneWidget);
  });

  testWidgets('bookmarks page renders empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),

        home: const BookmarksPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BookmarksPage), findsOneWidget);
    expect(find.text('Kaydedilenler'), findsOneWidget);
    expect(find.text('Henüz kaydedilmiş gönderin yok'), findsOneWidget);
  });
}
