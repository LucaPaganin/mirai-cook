import 'package:flutter/services.dart';

import '../../application/ports/shopping_list_exporter.dart';
import '../../domain/shopping_note.dart';

/// [ShoppingListExporter] adapter for Google Keep.
///
/// Google Keep's REST API is only available to Google Workspace domains, so
/// the note is handed to the Keep app with an Android share intent
/// (`ACTION_SEND` restricted to Keep's package). Keep creates a text note
/// with one item per line; "Mostra caselle di controllo" turns it into a
/// checklist.
class GoogleKeepExporter implements ShoppingListExporter {
  const GoogleKeepExporter();

  static const keepPackage = 'com.google.android.keep';
  static const _channel = MethodChannel('mirai_cook/export');

  @override
  Future<ExportResult> export(ShoppingNote note) async {
    try {
      final status = await _channel.invokeMethod<String>('shareText', {
        'title': note.title,
        'text': note.text,
        'package': keepPackage,
      });
      return status == 'done' ? const ExportDone() : const ExportUnavailable();
    } on MissingPluginException {
      return const ExportUnavailable(); // Not on Android.
    } on PlatformException catch (e) {
      return ExportFailed(e.message ?? e.code);
    }
  }
}
