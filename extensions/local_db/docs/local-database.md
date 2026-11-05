# Local database

Persist structured collections with the Sembast-backed `LocalDatabase` — an
offline-first store that the `connectivity` and `rest_auth` flows build on:

```dart
final database = RegistryScope.read<LocalDatabase>(context);
await database.put('tasks', '1', {'title': 'Write docs'});
final tasks = await database.query(
  'tasks',
  query: const LocalQuery(orderBy: 'title'),
);
```

`TypedCollection<T>` turns documents into models. `watch` emits a snapshot of the
collection every time the data changes.
