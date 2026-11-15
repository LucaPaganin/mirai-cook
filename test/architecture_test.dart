import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dart sources under [dir]; empty if the directory does not exist (e.g.
/// `integration_test/` before the first integration test is added).
List<File> dartFiles(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return const [];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList();
}

/// Source without comment lines.
String code(File f) =>
    f.readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

Iterable<String> imports(File f) => f
    .readAsLinesSync()
    .where((l) => l.startsWith('import ') || l.startsWith('export '))
    .map((l) => l.split("'")[1]);

String posix(File f) => f.path.replaceAll(r'\', '/');

/// The Riverpod providers file: the only place that picks adapters.
const compositionRoot = 'lib/application/providers.dart';

/// [uri] imported by [from] as a path from the project root (`lib/...`), or
/// unchanged for `dart:` and third-party `package:` imports.
String resolve(File from, String uri) {
  const self = 'package:mirai_cook/';
  if (uri.startsWith(self)) return 'lib/${uri.substring(self.length)}';
  if (uri.contains(':')) return uri;
  final parts = posix(from).split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      parts.removeLast();
    } else if (segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

void main() {
  // Covers: NFR-1, NFR-5
  test('domain is the pure core: no Flutter, Riverpod, IO or outer layers', () {
    const allowedPackages = [
      'package:html/',
      'package:meta/',
      'package:collection/',
    ];
    for (final f in dartFiles('lib/domain')) {
      for (final i in imports(f)) {
        final target = resolve(f, i);
        final ok = target.startsWith('lib/')
            ? target.startsWith('lib/domain/')
            : (i.startsWith('dart:') && i != 'dart:io' && i != 'dart:ui') ||
                  allowedPackages.any(i.startsWith);
        expect(ok, isTrue, reason: '${posix(f)} imports $i');
      }
    }
  });

  // Covers: NFR-2, PLAN-13
  test('system time is read only by SystemClock', () {
    for (final f in dartFiles('lib')) {
      if (f.path.endsWith('system_clock.dart')) continue;
      expect(code(f), isNot(contains('DateTime.now()')), reason: f.path);
    }
  });

  // Covers: NFR-2, NFR-5, DATA-2
  test('external packages are used only inside their adapter', () {
    const restricted = {
      'package:drift': ['lib/adapters/drift/'],
      'package:sqlite3': ['lib/adapters/drift/'],
      'package:http/': ['lib/adapters/http/', 'lib/adapters/google_drive/'],
      'package:googleapis': ['lib/adapters/google_drive/'],
      'package:google_sign_in': ['lib/adapters/google_drive/'],
      'package:workmanager': [
        'lib/adapters/workmanager/',
        'lib/background.dart',
      ],
      'package:path_provider': ['lib/adapters/system/'],
      'package:image/': ['lib/adapters/system/'],
      'package:flutter/services.dart': [
        'lib/adapters/android/',
        'lib/adapters/google_keep/',
        'lib/presentation/',
      ],
    };
    for (final f in dartFiles('lib')) {
      final path = posix(f);
      for (final i in imports(f)) {
        for (final entry in restricted.entries) {
          if (i.startsWith(entry.key)) {
            expect(
              entry.value.any(path.contains),
              isTrue,
              reason: '$path imports $i',
            );
          }
        }
      }
    }
  });

  // Covers: NFR-5
  test('ports are pure interfaces over the domain', () {
    final files = dartFiles('lib/application/ports');
    expect(files, isNotEmpty);
    for (final f in files) {
      for (final i in imports(f)) {
        final target = resolve(f, i);
        expect(
          target.startsWith('lib/domain/') ||
              target.startsWith('lib/application/ports/') ||
              const {'dart:async', 'dart:convert', 'dart:io'}.contains(i),
          isTrue,
          reason: '${posix(f)} imports $i',
        );
      }
    }
  });

  // Covers: NFR-5
  test('use cases depend on ports, never on adapters or the UI', () {
    for (final f in dartFiles('lib/application')) {
      final path = posix(f);
      if (path.contains('/ports/') || path == compositionRoot) continue;
      for (final i in imports(f)) {
        final target = resolve(f, i);
        expect(
          target.startsWith('lib/adapters/') ||
              target.startsWith('lib/presentation/') ||
              target == compositionRoot ||
              i.startsWith('package:flutter') ||
              i.startsWith('package:riverpod') ||
              i.startsWith('package:flutter_riverpod'),
          isFalse,
          reason: '$path imports $i',
        );
      }
    }
  });

  // Covers: NFR-5
  test('adapters implement ports and never depend on each other', () {
    for (final f in dartFiles('lib/adapters')) {
      final path = posix(f);
      final own = path.split('/').take(3).join('/'); // lib/adapters/<name>
      for (final i in imports(f)) {
        final target = resolve(f, i);
        if (!target.startsWith('lib/')) continue; // a package
        expect(
          target.startsWith('lib/domain/') ||
              target.startsWith('lib/application/ports/') ||
              target.startsWith('$own/'),
          isTrue,
          reason: '$path imports $i',
        );
      }
    }
  });

  // Covers: NFR-5
  test('only the composition root wires adapters', () {
    const allowed = {compositionRoot, 'lib/main.dart', 'lib/background.dart'};
    for (final f in dartFiles('lib')) {
      final path = posix(f);
      if (path.startsWith('lib/adapters/') || allowed.contains(path)) continue;
      for (final i in imports(f)) {
        expect(
          resolve(f, i).startsWith('lib/adapters/'),
          isFalse,
          reason: '$path imports $i',
        );
      }
    }
  });

  // Covers: NFR-3
  test('tests never build real network clients or read system time', () {
    for (final f in [...dartFiles('test'), ...dartFiles('integration_test')]) {
      if (f.path.endsWith('architecture_test.dart')) continue;
      final src = code(f);
      for (final forbidden in [
        'PackageHttpClient(',
        'GoogleDriveAccount(',
        'DriveBackupTarget(',
        'SystemClock(',
        'DateTime.now()',
      ]) {
        expect(
          src,
          isNot(contains(forbidden)),
          reason: '${f.path}: $forbidden',
        );
      }
    }
  });

  // Covers: NFR-4
  test('every requirement ID is covered by at least one test', () {
    final ids = RegExp(r'\*\*([A-Z]+-\d+)\*\*')
        .allMatches(File('docs/requirements.md').readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();
    final covered = <String>{};
    for (final f in [...dartFiles('test'), ...dartFiles('integration_test')]) {
      for (final line in f.readAsLinesSync()) {
        final i = line.indexOf('Covers:');
        if (i < 0) continue;
        covered.addAll(
          RegExp(r'[A-Z]+-\d+')
              .allMatches(line.substring(i))
              .map((m) => m.group(0)!),
        );
      }
    }
    expect(ids.difference(covered), isEmpty);
    expect(covered.difference(ids), isEmpty, reason: 'unknown IDs in tests');
  });
}
