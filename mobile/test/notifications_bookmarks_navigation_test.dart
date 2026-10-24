import 'package
:flutter
/material.dart';
import 'package
:flutter_test
/flutter_test.dart';
import 'package
:pulse
/features/pulse/presentation/bookmarks_page.dart';
import 'package
:pulse
/features/pulse/presentation/notifications_page.dart';
void main() {
Widget createApp() {
return MaterialApp(
home: const Scaffold(body:
NavigationFixture()),
routes: <String, WidgetBuilder>{
NotificationsPage.routeName: (
) => const NotificationsPage(),
BookmarksPage.routeName: (_) => const BookmarksPage(),
},
);
}
testWidgets('bildirimler route üzerinden açılır', (tester) async {
await tester.pumpWidget(createApp());
await tester.tap(find.byKey(const Key('notifications-button')));
await tester.pumpAndSettle();

expect(find.byType(NotificationsPage), findsOneWidget);
expect(find.text('Bildirimler'), findsOneWidget);
});
testWidgets('yer imleri route üzerinden açılır', (tester) async {
await tester.pumpWidget(createApp());
await tester.tap(find.byKey(const Key('bookmarks-button')));
await tester.pumpAndSettle();

expect(find.byType(BookmarksPage), findsOneWidget);
expect(find.text('Yer İmleri'), findsOneWidget);
});
}
class _NavigationFixture extends StatelessWidget {
const _NavigationFixture();
@override
Widget build(BuildContext context) {
return Column(
children:
<Widget>
[
TextButton(
key: const Key('notifications-button'),
onPressed: () {
Navigator.of(context).pushNamed(NotificationsPage.routeName);
},
child: const Text('Bildirimleri Aç'),
),
TextButton(
key: const Key('bookmarks-button'),
onPressed: () {
Navigator.of(context).pushNamed(BookmarksPage.routeName);
},
child: const Text('Yer İmlerini Aç'),
),
],
);
}
}