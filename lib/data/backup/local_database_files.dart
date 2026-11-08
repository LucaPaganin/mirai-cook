import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backup_target.dart';

class LocalDatabaseFiles implements DatabaseFiles {
  const LocalDatabaseFiles();

  static const fileName = 'mirai_cook.sqlite';

  @override
  Future<File> databaseFile() async =>
      File(p.join((await getApplicationSupportDirectory()).path, fileName));

  @override
  Future<Directory> tempDirectory() async =>
      (await getTemporaryDirectory()).createTemp('backup');

  @override
  Future<Directory> localSnapshotsDirectory() async {
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'snapshots'),
    );
    return dir.create(recursive: true);
  }
}
