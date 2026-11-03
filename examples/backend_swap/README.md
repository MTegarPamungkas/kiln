# Backend swap

Two Kiln apps with the same feature code and different backend extensions:

| Variant | Installed backend extension | Provides |
| --- | --- | --- |
| `with_appwrite` | `appwrite` | auth, remote database, file storage |
| `with_supabase` | `supabase` | auth, social auth, remote database, file storage |

`lib/features/notes/notes_page.dart` is byte-for-byte identical in both apps. It
imports only `kiln_core` for the `RemoteDatabase` contract and reads it from the
app's `RegistryScope`; there are no Appwrite or Supabase imports. The installed
extension decides which implementation the registry resolves at runtime.

The page lists documents from the `notes` collection and creates one through:

```dart
final database = RegistryScope.read<RemoteDatabase>(context);
await database.create('notes', {'title': ...});
final notes = await database.query('notes');
```

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

Tests run offline against a fake registry; no backend is contacted.
