import 'package:flutter/material.dart';

import '../../domain/tags.dart';

/// Chips for the recipe's tags, a field to add new ones and suggestions
/// from tags already in use (RCP-7, RCP-8).
class TagEditor extends StatefulWidget {
  const TagEditor({
    super.key,
    required this.tags,
    required this.known,
    required this.controller,
    required this.onChanged,
  });

  final List<String> tags;
  final List<String> known;
  final TextEditingController controller;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  void _add(String tag) {
    widget.onChanged(cleanTags([...widget.tags, tag]));
    widget.controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = suggestTags(
      widget.controller.text,
      widget.known,
      widget.tags,
    ).take(6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  key: Key('tag-chip-$tag'),
                  label: Text(tag),
                  onDeleted: () =>
                      widget.onChanged([...widget.tags]..remove(tag)),
                ),
            ],
          ),
        TextField(
          key: const Key('tag-field'),
          controller: widget.controller,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Tag',
            hintText: 'es. veloce, vegetariano, forno',
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) _add(v);
          },
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    key: Key('tag-suggestion-$s'),
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(s),
                    onPressed: () => _add(s),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
