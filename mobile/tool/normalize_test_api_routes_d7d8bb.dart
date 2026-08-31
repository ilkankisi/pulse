import 'dart:io';

const _apiRoutesImport = "import 'package:pulse/core/network/api_routes.dart';";

void main() {
  final root = Directory.current;

  final replacementsByFile = <String, List<MapEntry<String, String>>>{
    'test/api_client_test.dart': [
      const MapEntry("'/api/v1/feed'", 'ApiRoutes.feed'),
      const MapEntry('"/api/v1/feed"', 'ApiRoutes.feed'),
      const MapEntry("'/api/v1/posts'", 'ApiRoutes.posts'),
      const MapEntry('"/api/v1/posts"', 'ApiRoutes.posts'),
    ],
    'test/auth_flow_test.dart': [
      const MapEntry("'/api/v1/feed'", 'ApiRoutes.feed'),
      const MapEntry('"/api/v1/feed"', 'ApiRoutes.feed'),
      const MapEntry("'/api/v1/posts'", 'ApiRoutes.posts'),
      const MapEntry('"/api/v1/posts"', 'ApiRoutes.posts'),
    ],
    'test/profile_page_test.dart': [
      const MapEntry("'/api/v1/feed'", 'ApiRoutes.feed'),
      const MapEntry('"/api/v1/feed"', 'ApiRoutes.feed'),
    ],
    'test/pulse_repository_test.dart': [
      const MapEntry("'/api/v1/posts/10/likes'", 'ApiRoutes.postLikes(10)'),
      const MapEntry('"/api/v1/posts/10/likes"', 'ApiRoutes.postLikes(10)'),
      const MapEntry("'/api/v1/posts/10/replies'", 'ApiRoutes.postReplies(10)'),
      const MapEntry('"/api/v1/posts/10/replies"', 'ApiRoutes.postReplies(10)'),
      const MapEntry(
        "'/api/v1/profiles/ada/follow'",
        "ApiRoutes.profileFollow('ada')",
      ),
      const MapEntry(
        '"/api/v1/profiles/ada/follow"',
        "ApiRoutes.profileFollow('ada')",
      ),
      const MapEntry("'/api/v1/feed'", 'ApiRoutes.feed'),
      const MapEntry('"/api/v1/feed"', 'ApiRoutes.feed'),
      const MapEntry("'/api/v1/me'", 'ApiRoutes.me'),
      const MapEntry('"/api/v1/me"', 'ApiRoutes.me'),
      const MapEntry("'/api/v1/posts'", 'ApiRoutes.posts'),
      const MapEntry('"/api/v1/posts"', 'ApiRoutes.posts'),
    ],
    'test/safety_moderation_api_test.dart': [
      const MapEntry(
        "'/api/v1/moderation/reports/7/resolve'",
        'ApiRoutes.moderationResolve(7)',
      ),
      const MapEntry(
        '"/api/v1/moderation/reports/7/resolve"',
        'ApiRoutes.moderationResolve(7)',
      ),
      const MapEntry(
        "'/api/v1/moderation/reports'",
        'ApiRoutes.moderationReports',
      ),
      const MapEntry(
        '"/api/v1/moderation/reports"',
        'ApiRoutes.moderationReports',
      ),
      const MapEntry("'/api/v1/blocks'", 'ApiRoutes.blocks'),
      const MapEntry('"/api/v1/blocks"', 'ApiRoutes.blocks'),
    ],
  };

  for (final entry in replacementsByFile.entries) {
    final file = File(_resolve(root, entry.key));

    if (!file.existsSync()) {
      throw StateError('Missing required test file: ${entry.key}');
    }

    final original = file.readAsStringSync();
    var updated = original;
    var changed = false;

    for (final replacement in entry.value) {
      if (!updated.contains(replacement.key)) {
        continue;
      }

      updated = updated.replaceAll(replacement.key, replacement.value);
      changed = true;
    }

    if (changed && !updated.contains(_apiRoutesImport)) {
      updated = _insertImport(updated, _apiRoutesImport);
    }

    if (updated != original) {
      file.writeAsStringSync(updated);
      stdout.writeln('updated: ${entry.key}');
    }
  }

  _verify(root, replacementsByFile.keys);

  stdout.writeln('Canonical test API routes normalized successfully.');
}

String _resolve(Directory root, String relativePath) {
  final normalized = relativePath.replaceAll('/', Platform.pathSeparator);

  return '${root.path}${Platform.pathSeparator}$normalized';
}

String _insertImport(String source, String importLine) {
  final matches = RegExp(
    r'^import\s+.+?;\s*$',
    multiLine: true,
  ).allMatches(source).toList();

  final newline = _newline(source);

  if (matches.isEmpty) {
    return '$importLine$newline$source';
  }

  final lastImport = matches.last;
  var insertAt = lastImport.end;

  if (insertAt < source.length &&
      source.substring(insertAt).startsWith('\r\n')) {
    insertAt += 2;
  } else if (insertAt < source.length &&
      source.substring(insertAt).startsWith('\n')) {
    insertAt += 1;
  }

  return source.replaceRange(insertAt, insertAt, '$importLine$newline');
}

String _newline(String source) => source.contains('\r\n') ? '\r\n' : '\n';

void _verify(Directory root, Iterable<String> relativePaths) {
  const forbiddenLiterals = <String>[
    '/api/v1/feed',
    '/api/v1/me',
    '/api/v1/posts',
    '/api/v1/posts/10/likes',
    '/api/v1/posts/10/replies',
    '/api/v1/profiles/ada/follow',
    '/api/v1/blocks',
    '/api/v1/moderation/reports',
    '/api/v1/moderation/reports/7/resolve',
  ];

  final problems = <String>[];

  for (final relativePath in relativePaths) {
    final file = File(_resolve(root, relativePath));

    if (!file.existsSync()) {
      problems.add('$relativePath is missing.');
      continue;
    }

    final text = file.readAsStringSync();

    if (!text.contains(_apiRoutesImport)) {
      problems.add('$relativePath does not import canonical ApiRoutes.');
    }

    for (final path in forbiddenLiterals) {
      if (text.contains("'$path'") || text.contains('"$path"')) {
        problems.add(
          '$relativePath still contains duplicated route literal $path.',
        );
      }
    }
  }

  if (problems.isEmpty) {
    return;
  }

  stderr.writeln('Test API route normalization failed:');

  for (final problem in problems) {
    stderr.writeln('- $problem');
  }

  exitCode = 1;
  throw StateError('Canonical test route normalization is incomplete.');
}
