library
pulse_social_interaction_navigation_test;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse/presentation/bookmarks_page.dart';
import 'package:pulse/features/pulse/presentation/notifications_page.dart';
void main() {
Widget buildApp() {
return MaterialApp(
routes: <String, WidgetBuilder>{
NotificationsPage.routeName: (context) => const NotificationsPage(),
BookmarksPage.routeName: (context) => const BookmarksPage(),
},
home: Builder(
builder: (context) => Scaffold(
body: Column(
children: <Widget>[
TextButton(
key: const Key('open-notifications'),
onPressed: () => Navigator.of(
context,
).pushNamed(NotificationsPage.routeName),
child: const Text('Bildirimleri Aç'),
),
TextButton(
key: const Key('open-bookmarks'),
onPressed: () => Navigator.of(
context,
).pushNamed(BookmarksPage.routeName),
child: const Text('Yer İmlerini Aç'),
),
],
),
),
),
);
}
testWidgets('Notifications ekranı named route üzerinden açılır', (
tester,
) async {
await tester.pumpWidget(buildApp());
await tester.tap(find.byKey(const Key('open-notifications')));
await tester.pumpAndSettle();
expect(find.byType(NotificationsPage), findsOneWidget);
expect(find.text('Bildirimler'), findsOneWidget);
});
testWidgets('Bookmarks ekranı named route üzerinden açılır', (tester) async {
await tester.pumpWidget(buildApp());
await tester.tap(find.byKey(const Key('open-bookmarks')));
await tester.pumpAndSettle();
expect(find.byType(BookmarksPage), findsOneWidget);
expect(find.text('Yer İmleri'), findsOneWidget);
});
}