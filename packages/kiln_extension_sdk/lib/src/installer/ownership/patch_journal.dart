/// Reference-counts native patches shared by more than one extension.
final class PatchJournal {
  PatchJournal([Map<String, Set<String>>? owners])
    : _owners = <String, Set<String>>{
        if (owners != null)
          for (final entry in owners.entries)
            entry.key: <String>{...entry.value},
      };

  factory PatchJournal.fromJson(Map<String, Object?> json) {
    return PatchJournal(<String, Set<String>>{
      for (final entry in json.entries)
        entry.key: entry.value is Iterable
            ? (entry.value! as Iterable).map((value) => '$value').toSet()
            : <String>{},
    });
  }

  final Map<String, Set<String>> _owners;

  Map<String, Set<String>> get owners => <String, Set<String>>{
    for (final entry in _owners.entries)
      entry.key: Set<String>.unmodifiable(entry.value),
  };

  Set<String> ownersOf(String patchId) =>
      Set<String>.unmodifiable(_owners[patchId] ?? const <String>{});

  int referenceCount(String patchId) => _owners[patchId]?.length ?? 0;

  void register(String patchId, String owner) {
    _owners.putIfAbsent(patchId, () => <String>{}).add(owner);
  }

  /// Removes [owner]; returns true when no owner remains.
  bool unregister(String patchId, String owner) {
    final current = _owners[patchId];
    if (current == null) {
      return true;
    }
    current.remove(owner);
    if (current.isEmpty) {
      _owners.remove(patchId);
      return true;
    }
    return false;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    for (final entry in _owners.entries)
      entry.key: entry.value.toList()..sort(),
  };
}
