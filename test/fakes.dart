import 'dart:async';
import 'dart:io';

import 'package:mirai_cook/data/background_scheduler.dart';
import 'package:mirai_cook/data/backup/backup_target.dart';
import 'package:mirai_cook/data/http_client.dart';
import 'package:mirai_cook/data/share_intent.dart';
import 'package:mirai_cook/data/thumbnailer.dart';
import 'package:mirai_cook/domain/clock.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient([Map<String, HttpResponse>? responses])
    : responses = responses ?? {};

  final Map<String, HttpResponse> responses;
  final requested = <Uri>[];
  Object? throwOnGet;

  @override
  Future<HttpResponse> get(Uri url) async {
    requested.add(url);
    if (throwOnGet != null) throw throwOnGet!;
    return responses[url.toString()] ?? const HttpResponse(404, []);
  }
}

class FakeThumbnailer implements Thumbnailer {
  final inputs = <List<int>>[];

  @override
  Future<List<int>?> makeThumbnail(
    List<int> bytes, {
    int maxBytes = 50 * 1024,
  }) async {
    inputs.add(bytes);
    return [9, 9, 9];
  }
}

class FakeShareIntentSource implements ShareIntentSource {
  String? initialText;
  final controller = StreamController<String>.broadcast();

  @override
  Future<String?> takeInitialText() async {
    final t = initialText;
    initialText = null;
    return t;
  }

  @override
  Stream<String> get sharedTexts => controller.stream;
}

class FakeBackupTarget implements BackupTarget {
  final files = <String, (SnapshotInfo, List<int>)>{};
  Object? failWith;
  var _next = 0;

  @override
  Future<List<SnapshotInfo>> list() async {
    final all = files.values.map((e) => e.$1).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<void> upload(File file, SnapshotInfo info) async {
    if (failWith != null) throw failWith!;
    final id = 'f${_next++}';
    files[id] = (
      SnapshotInfo(
        id: id,
        name: info.name,
        createdAt: info.createdAt,
        recipeCount: info.recipeCount,
        schemaVersion: info.schemaVersion,
      ),
      await file.readAsBytes(),
    );
  }

  @override
  Future<void> download(String id, File destination) async {
    await destination.writeAsBytes(files[id]!.$2);
  }

  @override
  Future<void> delete(String id) async => files.remove(id);
}

class TempDatabaseFiles implements DatabaseFiles {
  TempDatabaseFiles() : root = Directory.systemTemp.createTempSync('mc');

  final Directory root;

  @override
  Future<File> databaseFile() async => File('${root.path}/db.sqlite');

  @override
  Future<Directory> tempDirectory() => root.createTemp('tmp');

  @override
  Future<Directory> localSnapshotsDirectory() =>
      Directory('${root.path}/snapshots').create(recursive: true);

  void dispose() => root.deleteSync(recursive: true);
}

class FakeBackupAccount implements BackupAccount {
  FakeBackupAccount(this.target);

  BackupTarget? target;
  bool connected = false;
  String email = 'cuoco@example.com';

  @override
  Future<String> connect() async {
    connected = true;
    return email;
  }

  @override
  Future<void> disconnect() async => connected = false;

  @override
  Future<BackupTarget?> silentTarget() async => connected ? target : null;
}

class FakeBackgroundScheduler implements BackgroundScheduler {
  int scheduled = 0;

  @override
  Future<void> scheduleDailyBackup() async => scheduled++;
}
