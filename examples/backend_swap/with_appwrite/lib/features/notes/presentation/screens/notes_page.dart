import 'package:flutter/material.dart';

import '../../../../app/registry_scope.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';

/// Backend-neutral notes screen.
///
/// The page depends only on the [NotesRepository] contract, which the
/// composition root fills from the registry, so the same file works unchanged
/// against Appwrite or Supabase. It never names a backend, an extension, or a
/// row shape.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  Future<List<Note>>? _notes;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notes ??= RegistryScope.read<NotesRepository>(context).fetchNotes();
  }

  Future<void> _createNote() async {
    if (_saving) {
      return;
    }
    final repository = RegistryScope.read<NotesRepository>(context);
    setState(() => _saving = true);
    try {
      await repository.createNote(
        'Note ${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _notes = repository.fetchNotes();
        _saving = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notes = Future<List<Note>>.error(error);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : _createNote,
              icon: const Icon(Icons.add),
              label: Text(_saving ? 'Saving...' : 'Create note'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Note>>(
                future: _notes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Could not load notes. '
                        'Check the backend connection and try again.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final notes = snapshot.data ?? const <Note>[];
                  if (notes.isEmpty) {
                    return const Center(
                      child: Text('No notes yet. Create the first one.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return ListTile(
                        leading: const Icon(Icons.note_outlined),
                        title: Text(note.body),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
