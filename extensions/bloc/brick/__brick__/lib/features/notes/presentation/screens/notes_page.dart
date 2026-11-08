import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{app_name}}/app/registry_scope.dart';
import 'package:{{app_name}}/features/notes/feature.dart';
import 'package:{{app_name}}/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:{{app_name}}/features/notes/presentation/bloc/notes_event.dart';
import 'package:{{app_name}}/features/notes/presentation/bloc/notes_state.dart';
import 'package:{{app_name}}/features/notes/presentation/widgets/note_tile.dart';

/// Entry point of the sample feature.
///
/// The page owns its bloc: it is created here and disposed with the route, so
/// no global provider is needed for a single screen.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = RegistryScope.of(context);
    return BlocProvider<NotesBloc>(
      create: (_) => createNotesBloc(registry),
      child: const NotesView(),
    );
  }
}

/// List, composer, and failure surface for [NotesBloc].
class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final TextEditingController _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _submit(String body) {
    context.read<NotesBloc>().add(NoteAdded(body));
    _composer.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: BlocConsumer<NotesBloc, NotesState>(
        listenWhen: (previous, current) => previous.problem != current.problem,
        listener: (context, state) {
          final problem = state.problem;
          if (problem == null) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(problem.message)));
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.notes.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }
          return ListView.separated(
            itemCount: state.notes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = state.notes[index];
              return NoteTile(
                note: note,
                onToggle: () =>
                    context.read<NotesBloc>().add(NoteToggled(note.id)),
                onRemove: () =>
                    context.read<NotesBloc>().add(NoteRemoved(note.id)),
              );
            },
          );
        },
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
}
