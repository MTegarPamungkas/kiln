# Backend swap

Two Kiln apps with the same feature code and different backend extensions:

| Variant | Installed backend extension | Provides |
| --- | --- | --- |
| `with_appwrite` | `appwrite` | auth, remote database, file storage |
| `with_supabase` | `supabase` | auth, social auth, remote database, file storage |

Everything under `lib/features/notes/` is byte-for-byte identical in both apps,
as are `lib/main.dart`, `lib/app/`, and `lib/core/`. The backend, its
dependencies (`pubspec.yaml`), and the extension answers in `kiln.yaml` differ.
That is the point of the example: swapping the backend never touches feature
code.

The feature follows the same clean-architecture folders that the `bloc` and
`riverpod` extensions install (see `ARCHITECTURE.md` in a state-enabled app),
even though both variants here are created with `state: none`:

```text
lib/features/notes/
  domain/
    entities/note.dart            the Note value object
    repositories/                 NotesRepository, the contract the page needs
  data/
    models/note_dto.dart          remote row -> Note
    repositories/                 NotesRepositoryImpl over RemoteDatabase
  presentation/
    screens/notes_page.dart       reads the contract, never a backend
  feature.dart                    barrel + the one-line composition
```

`test/` mirrors `lib/` one for one, so the tests sit at
`test/features/notes/<layer>/...`.

Nothing in `lib/features/` names Appwrite or Supabase. `presentation/` imports
only `domain/`, and `data/` speaks the backend-neutral `RemoteDatabase` contract
from `kiln_core` that it reads out of the app's `RegistryScope`. The installed
extension decides which implementation the registry resolves at runtime, and the
row mapping is shared because both adapters normalise the row id into `id`.

The binding is made once in the composition root:

```dart
// lib/main.dart
registry.registerLazySingleton<NotesRepository>(
  () => notesRepository(registry),
);
```

```dart
// lib/features/notes/feature.dart
NotesRepository notesRepository(Registry registry) {
  return NotesRepositoryImpl(database: registry.read<RemoteDatabase>());
}
```

The page lists documents from the `notes` collection and creates one through the
contract, so it has no idea a backend exists:

```dart
final repository = RegistryScope.read<NotesRepository>(context);
await repository.createNote('Buy milk');
final notes = await repository.fetchNotes();
```

Note that `NotesRepositoryImpl.createNote` writes exactly one column,
`{'title': ...}`. Writing the optional `done` or `updated_at` columns would be
rejected by the single-field collection this example documents, so those two
fields are read-only and tolerated when absent.

## Run a variant

From the repository root:

```bash
cd examples/backend_swap/with_appwrite
flutter pub get
flutter run -d chrome   # or another device

cd examples/backend_swap/with_supabase
flutter pub get
flutter run -d chrome
```

The variants are generated with placeholder credentials
(`https://api.example.com`, `https://example.supabase.co`, `test-anon-key`).
Create a `notes` collection/table with a `title` field and put real connection
settings in each app's `lib/extensions/<backend>/<backend>_config.dart` before
talking to a live backend.

To swap backends in another app, install the other extension instead of editing
feature code (run inside that app):

```bash
kiln add supabase
```

## Verify

```bash
cd examples/backend_swap/with_appwrite && flutter analyze && flutter test
cd examples/backend_swap/with_supabase && flutter analyze && flutter test
```

The identity claim is checkable from this directory — it prints nothing when the
feature code still matches:

```bash
diff -r with_appwrite/lib/features/notes with_supabase/lib/features/notes
diff with_appwrite/lib/main.dart with_supabase/lib/main.dart
```

Tests run offline against a fake registry; no backend is contacted.
