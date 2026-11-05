/// A slot an extension opens for other extensions to contribute to.
final class SlotDeclaration {
  const SlotDeclaration({
    required this.name,
    required this.item,
    this.description,
  });

  final String name;
  final String item;
  final String? description;

  static SlotDeclaration fromMap(Map<String, Object?> map) {
    return SlotDeclaration(
      name: '${map['name'] ?? ''}',
      item: '${map['item'] ?? ''}',
      description: map['description'] as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'item': item,
    if (description != null) 'description': description,
  };
}
