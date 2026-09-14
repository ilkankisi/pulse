import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pulse presentation contract', () {
    test('FeedPage ikinci floating action button tanımlamaz', () {
      final source = File(
        'lib/features/pulse/presentation/feed_page.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('floatingActionButton:')));
    });

    test('FeedPage empty state CTA body içinde korunur', () {
      final source = File(
        'lib/features/pulse/presentation/feed_page.dart',
      ).readAsStringSync();

      expect(source, contains('_EmptyFeed(onCreate: _openComposer)'));
      expect(source, contains("label: const Text('Gönderi Oluştur')"));
      expect(source, contains('FilledButton.icon('));
    });

    test('AppShell compose FAB sahibi olmaya devam eder', () {
      final source = File(
        'lib/features/pulse/presentation/app_shell.dart',
      ).readAsStringSync();

      expect(source, contains('floatingActionButton: _selectedIndex == 0'));
      expect(source, contains('FloatingActionButton.extended('));
      expect(source, contains('onPressed: _openComposer'));
    });
  });
}
