/// An item this extension contributes to a slot opened by another extension.
final class Contribution {
  const Contribution({
    required this.slot,
    this.item,
    this.priority = 0,
    this.when = const <String>[],
    this.description,
  });

  final String slot;
  final String? item;
  final int priority;

  /// Capability names that must all be present for this contribution to load.
  final List<String> when;
  final String? description;

  bool isActive(Set<String> capabilities) => when.every(capabilities.contains);

  static Contribution fromMap(Map<String, Object?> map) {
    return Contribution(
      slot: '${map['slot'] ?? ''}',
      item: map['item'] as String?,
      priority: _asInt(map['priority']) ?? 0,
      when: _stringList(map['when']),
      description: map['description'] as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'slot': slot,
    if (item != null) 'item': item,
    if (priority != 0) 'priority': priority,
    if (when.isNotEmpty) 'when': when,
    if (description != null) 'description': description,
  };

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }
    return value.map((entry) => '$entry').toList(growable: false);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return value == null ? null : int.tryParse('$value');
  }
}
