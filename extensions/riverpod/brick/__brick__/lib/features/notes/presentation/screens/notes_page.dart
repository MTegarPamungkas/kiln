import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/presentation/providers/notes_controller.dart';
import 'package:{{app_name}}/features/notes/presentation/widgets/note_tile.dart';

/// Entry point of the sample feature.
///
/// Riverpod owns the dependency graph, so the page reads providers directly
/// and no widget-level provider wrapper is needed.
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  NotesController get _controller => ref.read(notesControllerProvider.notifier);

  Future<void> _submit(String body) async {
    await _controller.add(body);
    _composer.clear();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.when(
        data: (items) => _list(items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _problem(error),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('notes-composer'),
                  controller: _composer,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'New note',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('notes-add'),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add note',
                onPressed: () => _submit(_composer.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Note> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No notes yet'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = items[index];
        return NoteTile(
          note: note,
          onToggle: () => _controller.toggle(note.id),
          onRemove: () => _controller.remove(note.id),
        );
      },
    );
  }

  /// A [Failure] carries user-facing copy, so the screen shows its message.
  Widget _problem(Object error) {
    final message = error is Failure
        ? error.message
        : 'The note list is unavailable';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(notesControllerProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
