import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .toList();

/// Source without comment lines.
String code(File f) =>
    f.readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

Iterable<String> imports(File f) => f
    .readAsLinesSync()
    .where((l) => l.startsWith('import '))
    .map((l) => l.split("'")[1]);

void main() {
  // Covers: NFR-1
  test('domain is pure Dart: no Flutter, Riverpod, Drift or IO', () {
    for (final f in dartFiles('lib/domain')) {
      for (final i in imports(f)) {
        expect(
          i,
          isNot(
            anyOf(
              startsWith('package:flutter'),
              startsWith('package:riverpod'),
              startsWith('package:flutter_riverpod'),
              startsWith('package:drift'),
              startsWith('package:http'),
              'dart:io',
            ),
          ),
          reason: '${f.path} imports $i',
        );
      }
    }
  });

  // Covers: NFR-2, PLAN-13
  test('system time is read only by SystemClock', () {
    for (final f in dartFiles('lib')) {
      if (f.path.endsWith('system_clock.dart')) continue;
      expect(
        code(f),
        isNot(contains('DateTime.now()')),
        reason: f.path,
      );
    }
  });

  // Covers: NFR-2, DATA-2
  test('network and platform packages are used only behind interfaces', () {
    const restricted = {
      'package:http/': ['lib/data/http_client.dart', 'lib/data/backup/'],
      'package:googleapis': ['lib/data/backup/'],
      'package:google_sign_in': ['lib/data/backup/'],
      'package:workmanager': [
        'lib/data/background_scheduler.dart',
        'lib/background.dart',
      ],
      'package:path_provider': ['lib/data/backup/local_database_files.dart'],
    };
    for (final f in dartFiles('lib')) {
      final path = f.path.replaceAll(r'\', '/');
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
