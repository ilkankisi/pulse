import 'dart:io';

void main() {
  final file = File('test/profile_page_test.dart');

  if (!file.existsSync()) {
    throw StateError('Missing test/profile_page_test.dart');
  }

  final original = file.readAsStringSync();
  var updated = original;

  updated = _replaceProfilePostsPath(updated, username: 'ilkan', occurrence: 1);

  updated = _replaceProfilePostsPath(updated, username: 'ayse', occurrence: 1);

  if (updated == original) {
    _verify(updated);
    stdout.writeln('profile_page_test.dart already aligned.');
    return;
  }

  file.writeAsStringSync(updated);
  _verify(updated);

  stdout.writeln('profile_page_test.dart aligned.');
}

String _replaceProfilePostsPath(
  String source, {
  required String username,
  required int occurrence,
}) {
  const legacy = 'const postsPath = ApiRoutes.feed;';

  var searchStart = 0;
  var targetIndex = -1;

  for (var index = 0; index < occurrence; index++) {
    targetIndex = source.indexOf(legacy, searchStart);

    if (targetIndex < 0) {
      return source;
    }

    searchStart = targetIndex + legacy.length;
  }

  return source.replaceRange(
    targetIndex,
    targetIndex + legacy.length,
    "final postsPath = '/api/v1/profiles/$username/posts';",
  );
}

void _verify(String source) {
  final problems = <String>[];

  if (source.contains('const postsPath = ApiRoutes.feed;')) {
    problems.add(
      'profile_page_test.dart still uses ApiRoutes.feed for profile posts.',
    );
  }

  if (!source.contains('/api/v1/profiles/ilkan/posts')) {
    problems.add('Missing canonical ilkan profile posts mock path.');
  }

  if (!source.contains('/api/v1/profiles/ayse/posts')) {
    problems.add('Missing canonical ayse profile posts mock path.');
  }

  if (problems.isEmpty) {
    return;
  }

  for (final problem in problems) {
    stderr.writeln(problem);
  }

  throw StateError('Profile posts test alignment failed.');
}
