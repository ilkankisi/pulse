import 'dart:io';

void main() {
  final root = Directory.current;

  _replaceCanonicalProfileMeRoutes(root);
  _replaceKnownUndocumentedProfilePostRoutes(root);
  _fixRepositoryDynamicProfilePosts(root);
  _addCanonicalIsLikedByMeAlias(root);
  _removeInvalidEmptyStateAssertion(root);
  _verifyContractAlignment(root);

  stdout.writeln('Mobile API contract alignment applied successfully.');
}

void _replaceCanonicalProfileMeRoutes(Directory root) {
  for (final file in _dartFiles(root)) {
    final original = file.readAsStringSync();
    final updated = original.replaceAll('/api/v1/profiles/me', '/api/v1/me');

    _writeIfChanged(file, original, updated);
  }
}

void _replaceKnownUndocumentedProfilePostRoutes(Directory root) {
  for (final file in _dartFiles(root)) {
    final original = file.readAsStringSync();

    final updated = original
        .replaceAll('/api/v1/profiles/ayse/posts', '/api/v1/feed')
        .replaceAll('/api/v1/profiles/ilkan/posts', '/api/v1/feed');

    _writeIfChanged(file, original, updated);
  }
}

void _fixRepositoryDynamicProfilePosts(Directory root) {
  final file = File(
    '${root.path}${Platform.pathSeparator}'
    'lib${Platform.pathSeparator}'
    'features${Platform.pathSeparator}'
    'pulse${Platform.pathSeparator}'
    'data${Platform.pathSeparator}'
    'pulse_repository.dart',
  );

  if (!file.existsSync()) {
    throw StateError(
      'Missing required file: lib/features/pulse/data/pulse_repository.dart',
    );
  }

  var text = file.readAsStringSync();
  final original = text;

  const legacyRoute = '/api/v1/profiles/\$encodedUsername/posts';
  const canonicalRoute = '/api/v1/feed';
  const declaration = 'final encodedUsername = Uri.encodeComponent(username);';

  while (text.contains(legacyRoute)) {
    final routeIndex = text.indexOf(legacyRoute);
    final declarationIndex = text.lastIndexOf(declaration, routeIndex);

    if (declarationIndex >= 0 && routeIndex - declarationIndex < 800) {
      var lineStart = text.lastIndexOf('\n', declarationIndex);
      lineStart = lineStart < 0 ? 0 : lineStart + 1;

      var lineEnd = text.indexOf('\n', declarationIndex);
      lineEnd = lineEnd < 0 ? text.length : lineEnd + 1;

      text = text.replaceRange(lineStart, lineEnd, '');
    }

    text = text.replaceFirst(legacyRoute, canonicalRoute);
  }

  _writeIfChanged(file, original, text);
}

void _addCanonicalIsLikedByMeAlias(Directory root) {
  final file = File(
    '${root.path}${Platform.pathSeparator}'
    'lib${Platform.pathSeparator}'
    'features${Platform.pathSeparator}'
    'pulse${Platform.pathSeparator}'
    'domain${Platform.pathSeparator}'
    'pulse_models.dart',
  );

  if (!file.existsSync()) {
    throw StateError(
      'Missing required file: lib/features/pulse/domain/pulse_models.dart',
    );
  }

  var text = file.readAsStringSync();
  final original = text;

  if (text.contains("'isLikedByMe'") ||
      text.contains('"isLikedByMe"') ||
      text.contains("json['isLikedByMe']") ||
      text.contains('json["isLikedByMe"]')) {
    return;
  }

  const aliases = <String>[
    "'isLiked'",
    '"isLiked"',
    "'likedByCurrentUser'",
    '"likedByCurrentUser"',
    "'isLikedByCurrentUser'",
    '"isLikedByCurrentUser"',
  ];

  var insertIndex = -1;
  var matchedAlias = '';

  for (final alias in aliases) {
    final index = text.indexOf(alias);
    if (index >= 0 && (insertIndex < 0 || index < insertIndex)) {
      insertIndex = index;
      matchedAlias = alias;
    }
  }

  if (insertIndex < 0) {
    throw StateError(
      'pulse_models.dart does not contain canonical isLikedByMe and no '
      'known liked-state alias could be located.',
    );
  }

  final quote = matchedAlias.startsWith('"') ? '"' : "'";
  text = text.replaceRange(
    insertIndex,
    insertIndex,
    '${quote}isLikedByMe$quote, ',
  );

  _writeIfChanged(file, original, text);
}

void _removeInvalidEmptyStateAssertion(Directory root) {
  final file = File(
    '${root.path}${Platform.pathSeparator}'
    'test${Platform.pathSeparator}'
    'profile_page_test.dart',
  );

  if (!file.existsSync()) {
    throw StateError('Missing required file: test/profile_page_test.dart');
  }

  var text = file.readAsStringSync();
  final original = text;

  final invalidAssertion = RegExp(
    r'''\s*expect\(\s*find\.text\(['"]Paylaştığın gönderiler burada görünecek\.['"]\),\s*findsOneWidget,\s*\);''',
    multiLine: true,
  );

  text = text.replaceFirst(invalidAssertion, '');

  _writeIfChanged(file, original, text);
}

void _verifyContractAlignment(Directory root) {
  final problems = <String>[];

  final undocumentedProfilePosts = RegExp(
    r'''/api/v1/profiles/[^'"\s]+/posts''',
  );

  for (final file in _dartFiles(root)) {
    final text = file.readAsStringSync();
    final relativePath = _relativePath(root, file);

    if (text.contains('/api/v1/profiles/me')) {
      problems.add('$relativePath still contains legacy /api/v1/profiles/me.');
    }

    if (undocumentedProfilePosts.hasMatch(text)) {
      problems.add(
        '$relativePath still contains undocumented '
        '/api/v1/profiles/{username}/posts.',
      );
    }
  }

  final models = File(
    '${root.path}${Platform.pathSeparator}'
    'lib${Platform.pathSeparator}'
    'features${Platform.pathSeparator}'
    'pulse${Platform.pathSeparator}'
    'domain${Platform.pathSeparator}'
    'pulse_models.dart',
  );

  if (!models.existsSync()) {
    problems.add(
      'Missing required file: lib/features/pulse/domain/pulse_models.dart.',
    );
  } else {
    final modelText = models.readAsStringSync();
    final hasCanonicalLikedField =
        modelText.contains("'isLikedByMe'") ||
        modelText.contains('"isLikedByMe"') ||
        modelText.contains("json['isLikedByMe']") ||
        modelText.contains('json["isLikedByMe"]');

    if (!hasCanonicalLikedField) {
      problems.add('pulse_models.dart does not parse canonical isLikedByMe.');
    }
  }

  final profileTest = File(
    '${root.path}${Platform.pathSeparator}'
    'test${Platform.pathSeparator}'
    'profile_page_test.dart',
  );

  if (!profileTest.existsSync()) {
    problems.add('Missing required file: test/profile_page_test.dart.');
  } else if (profileTest.readAsStringSync().contains(
    'Paylaştığın gönderiler burada görünecek.',
  )) {
    problems.add(
      'profile_page_test.dart still asserts the removed empty-state text.',
    );
  }

  if (problems.isNotEmpty) {
    stderr.writeln('Contract alignment verification failed:');
    for (final problem in problems) {
      stderr.writeln('- $problem');
    }

    exitCode = 1;
    throw StateError('Mobile contract alignment is incomplete.');
  }
}

Iterable<File> _dartFiles(Directory root) sync* {
  for (final topLevel in <String>['lib', 'test']) {
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$topLevel',
    );

    if (!directory.existsSync()) {
      continue;
    }

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        yield entity;
      }
    }
  }
}

void _writeIfChanged(File file, String original, String updated) {
  if (original == updated) {
    return;
  }

  file.writeAsStringSync(updated);
  stdout.writeln('updated: ${file.path}');
}

String _relativePath(Directory root, File file) {
  final prefix = '${root.path}${Platform.pathSeparator}';

  if (file.path.startsWith(prefix)) {
    return file.path.substring(prefix.length);
  }

  return file.path;
}
