import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

import '../../domain/clock.dart';
import 'backup_target.dart';

/// Snapshots in a visible "Mirai Cook backup" Drive folder, using only the
/// `drive.file` scope (DATA-6).
class DriveBackupTarget implements BackupTarget {
  DriveBackupTarget(http.Client client) : _api = drive.DriveApi(client);

  static const folderName = 'Mirai Cook backup';
  static const _folderMime = 'application/vnd.google-apps.folder';

  final drive.DriveApi _api;
  String? _folderId;

  Future<String> _folder() async {
    if (_folderId != null) return _folderId!;
    final found = await _api.files.list(
      q: "mimeType = '$_folderMime' and name = '$folderName' and trashed = false",
      $fields: 'files(id)',
      spaces: 'drive',
    );
    final existing = found.files ?? const [];
    if (existing.isNotEmpty) return _folderId = existing.first.id!;
    final created = await _api.files.create(
      drive.File(name: folderName, mimeType: _folderMime),
      $fields: 'id',
    );
    return _folderId = created.id!;
  }

  @override
  Future<List<SnapshotInfo>> list() async {
    final folder = await _folder();
    final result = <SnapshotInfo>[];
    String? pageToken;
    do {
      final page = await _api.files.list(
        q: "'$folder' in parents and trashed = false",
        orderBy: 'createdTime desc',
        $fields: 'nextPageToken, files(id, name, createdTime, appProperties)',
        pageToken: pageToken,
      );
      for (final f in page.files ?? const <drive.File>[]) {
        final props = f.appProperties ?? const {};
        result.add(
          SnapshotInfo(
            id: f.id!,
            name: f.name ?? '',
            createdAt:
                DateTime.tryParse(props['createdAt'] ?? '') ??
                f.createdTime ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            recipeCount: int.tryParse(props['recipeCount'] ?? ''),
            schemaVersion: int.tryParse(props['schemaVersion'] ?? ''),
          ),
        );
      }
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> upload(File file, SnapshotInfo info) async {
    final folder = await _folder();
    await _api.files.create(
      drive.File(
        name: info.name,
        parents: [folder],
        mimeType: 'application/x-sqlite3',
        appProperties: {
          'createdAt': info.createdAt.toUtc().toIso8601String(),
          if (info.recipeCount != null) 'recipeCount': '${info.recipeCount}',
          if (info.schemaVersion != null)
            'schemaVersion': '${info.schemaVersion}',
        },
      ),
      uploadMedia: drive.Media(file.openRead(), await file.length()),
      $fields: 'id',
    );
  }

  @override
  Future<void> download(String id, File destination) async {
    final media = await _api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final sink = destination.openWrite();
    await media.stream.pipe(sink);
  }

  @override
  Future<void> delete(String id) => _api.files.delete(id);
}

/// Google account access for Drive (DATA-12).
class GoogleDriveAccount implements BackupAccount {
  GoogleDriveAccount(this._clock, {this.serverClientId});

  static const scopes = [drive.DriveApi.driveFileScope];

  final Clock _clock;
  final String? serverClientId;
  Future<void>? _init;

  GoogleSignIn get _signIn => GoogleSignIn.instance;

  Future<void> _ensureInit() => _init ??= _signIn.initialize(
    serverClientId: serverClientId?.isEmpty ?? true ? null : serverClientId,
  );

  @override
  Future<String> connect() async {
    await _ensureInit();
    final account = await _signIn.authenticate(scopeHint: scopes);
    await account.authorizationClient.authorizeScopes(scopes);
    return account.email;
  }

  @override
  Future<void> disconnect() async {
    await _ensureInit();
    await _signIn.disconnect();
  }

  @override
  Future<BackupTarget?> silentTarget() async {
    await _ensureInit();
    final authz = await _signIn.authorizationClient.authorizationForScopes(
      scopes,
    );
    if (authz == null) return null;
    final credentials = auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        authz.accessToken,
        _clock.now().toUtc().add(const Duration(minutes: 50)),
      ),
      null,
      scopes,
    );
    return DriveBackupTarget(
      auth.authenticatedClient(http.Client(), credentials),
    );
  }
}
