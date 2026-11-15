import 'package:flutter/services.dart';

import '../../application/ports/shopping_list_exporter.dart';
import '../../domain/shopping_note.dart';

/// [ShoppingListExporter] adapter: the Android share sheet, so the user picks
/// any app (fallback when Google Keep is missing, EXP-3).
class ShareSheetExporter implements ShoppingListExporter {
  const ShareSheetExporter();

  static const _channel = MethodChannel('mirai_cook/export');

  @override
  Future<ExportResult> export(ShoppingNote note) async {
    try {
      final status = await _channel.invokeMethod<String>('shareText', {
        'title': note.title,
        'text': note.text,
      });
      return status == 'done' ? const ExportDone() : const ExportUnavailable();
    } on MissingPluginException {
      return const ExportUnavailable();
    } on PlatformException catch (e) {
      return ExportFailed(e.message ?? e.code);
    }
  }
}
