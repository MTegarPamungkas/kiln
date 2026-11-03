# Local database

```dart
final database = RegistryScope.read<LocalDatabase>(context);
await database.put('tasks', '1', {'title': 'Write docs'});
final tasks = await database.query(
  'tasks',
  query: const LocalQuery(orderBy: 'title'),
);
```

`TypedCollection<T>` mengubah dokumen menjadi model. `watch` memancarkan
snapshot koleksi setiap kali data berubah.
