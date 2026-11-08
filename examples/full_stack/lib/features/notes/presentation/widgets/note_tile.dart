import 'package:flutter/material.dart';
import 'package:full_stack/features/notes/domain/entities/note.dart';

/// One row of the notes list.
class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onToggle,
    required this.onRemove,
    super.key,
  });

  final Note note;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Checkbox(value: note.isDone, onChanged: (_) => onToggle()),
      title: Text(
        note.body,
        style: note.isDone
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: colors.onSurfaceVariant,
              )
            : null,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        tooltip: 'Remove note',
        onPressed: onRemove,
      ),
      onTap: onToggle,
    );
  }
}
