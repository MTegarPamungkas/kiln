import 'dart:async';

/// Well-known slot names. Extensions may open additional slots.
abstract final class SlotNames {
  static const registry = 'registry';
  static const httpInterceptors = 'http.interceptors';
  static const httpMiddleware = 'http.middleware';
  static const routerRoutes = 'router.routes';
  static const appWrappers = 'app.wrappers';
}

/// One item contributed to a slot.
final class SlotEntry<T> {
  const SlotEntry({
    required this.item,
    required this.priority,
    required this.order,
    this.owner,
  });

  final T item;
  final int priority;
  final int order;
  final String? owner;
}

/// An ordered list of contributions with a stable tie-breaker.
///
/// Lower priority runs first. Items with equal priority keep insertion order.
final class OrderedSlot<T> {
  OrderedSlot(this.name);

  final String name;
  final List<SlotEntry<T>> _entries = <SlotEntry<T>>[];
  final StreamController<List<T>> _changes =
      StreamController<List<T>>.broadcast(sync: true);
  int _sequence = 0;

  List<SlotEntry<T>> get entries => List<SlotEntry<T>>.unmodifiable(_sorted());

  List<T> get items =>
      List<T>.unmodifiable(_sorted().map((entry) => entry.item));

  Stream<List<T>> get changes => _changes.stream;

  void add(T item, {int priority = 0, String? owner}) {
    _entries.add(
      SlotEntry<T>(
        item: item,
        priority: priority,
        order: _sequence++,
        owner: owner,
      ),
    );
    _emit();
  }

  void removeOwner(String owner) {
    final before = _entries.length;
    _entries.removeWhere((entry) => entry.owner == owner);
    if (_entries.length != before) {
      _emit();
    }
  }

  void remove(T item) {
    final index = _entries.indexWhere((entry) => identical(entry.item, item));
    if (index < 0) {
      return;
    }
    _entries.removeAt(index);
    _emit();
  }

  void clear() {
    if (_entries.isEmpty) {
      return;
    }
    _entries.clear();
    _emit();
  }

  void _emit() {
    _changes.add(items);
  }

  List<SlotEntry<T>> _sorted() {
    final sorted = <SlotEntry<T>>[..._entries];
    sorted.sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      return byPriority != 0 ? byPriority : a.order.compareTo(b.order);
    });
    return sorted;
  }

  Future<void> dispose() => _changes.close();
}

/// Owns every open slot. Modules open a slot before contributing to it.
final class SlotRegistry {
  final Map<String, Object> _slots = <String, Object>{};

  bool has(String name) => _slots.containsKey(name);

  OrderedSlot<T> open<T>(String name) {
    final existing = _slots[name];
    if (existing == null) {
      final slot = OrderedSlot<T>(name);
      _slots[name] = slot;
      return slot;
    }
    if (existing is OrderedSlot<T>) {
      return existing;
    }
    throw StateError('Slot "$name" is already open with a different item type');
  }

  OrderedSlot<T>? find<T>(String name) {
    final existing = _slots[name];
    return existing is OrderedSlot<T> ? existing : null;
  }

  Future<void> dispose() async {
    for (final slot in _slots.values) {
      if (slot is OrderedSlot<Object?>) {
        await slot.dispose();
      }
    }
    _slots.clear();
  }
}
