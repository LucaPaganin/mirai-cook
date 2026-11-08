import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/recipe_importer.dart';
import '../../domain/recipe.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/recipe_editor_screen.dart';

/// IMP-2: asks for a URL (prefilled from the clipboard) and imports it.
Future<void> showImportDialog(BuildContext context) async {
  final clip = await Clipboard.getData(Clipboard.kTextPlain);
  final clipText = clip?.text ?? '';
  if (!context.mounted) return;
  final input = await showDialog<String>(
    context: context,
    builder: (_) => _ImportUrlDialog(
      initial: extractUrl(clipText) == null ? '' : clipText.trim(),
    ),
  );
  if (input == null || input.trim().isEmpty || !context.mounted) return;
  await openImport(context, input);
}

class _ImportUrlDialog extends StatefulWidget {
  const _ImportUrlDialog({required this.initial});

  final String initial;

  @override
  State<_ImportUrlDialog> createState() => _ImportUrlDialogState();
}

class _ImportUrlDialogState extends State<_ImportUrlDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Importa da URL'),
        content: TextField(
          key: const Key('import-url'),
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://…'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Importa'),
          ),
        ],
      );
}

Future<void> openImport(BuildContext context, String input) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => ImportScreen(input: input)),
);

/// Runs an import and routes to the editor, the existing recipe, or an
/// error with retry (IMP-5, IMP-6, IMP-8, IMP-9).
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.input});

  final String input;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportResult? _result;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run({bool allowDuplicate = false}) async {
    setState(() => _result = null);
    final result = await ref
        .read(recipeImporterProvider)
        .import(widget.input, allowDuplicate: allowDuplicate);
    if (!mounted) return;
    if (result is ImportDraft) {
      if (!result.structured) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nessuna ricetta trovata nella pagina: '
              'completala a mano.',
            ),
          ),
        );
      }
      await openRecipeEditor(context, result.recipe, replace: true);
      return;
    }
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Importa ricetta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (result) {
          null => const Center(child: CircularProgressIndicator()),
          ImportDuplicate(:final existing) => _Message(
            icon: Icons.content_copy,
            text: 'Hai già questa ricetta: "${existing.title}".',
            actions: [
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RecipeDetailScreen(recipeId: existing.id!),
                  ),
                ),
                child: const Text('Apri'),
              ),
              TextButton(
                onPressed: () => _run(allowDuplicate: true),
                child: const Text('Importa comunque'),
              ),
            ],
          ),
          ImportFailure(:final message, :final url) => _Message(
            icon: Icons.cloud_off,
            text: message,
            detail: url?.toString() ?? widget.input,
            actions: [
              if (url != null)
                FilledButton(onPressed: _run, child: const Text('Riprova')),
              TextButton(
                onPressed: () => openRecipeEditor(
                  context,
                  Recipe(
                    title: '',
                    servings: RecipeImporter.defaultServings,
                    sourceUrl: url?.toString(),
                  ),
                  replace: true,
                ),
                child: const Text('Continua a mano'),
              ),
            ],
          ),
          ImportDraft() => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.actions,
    this.detail,
  });

  final IconData icon;
  final String text;
  final String? detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center),
        if (detail != null) ...[
          const SizedBox(height: 8),
          SelectableText(
            detail!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        Wrap(spacing: 12, children: actions),
      ],
    ),
  );
}
