import 'package:yaml/yaml.dart';

import '../kiln_exception.dart';
import 'migration_actions.dart';

/// One migration step between two extension versions.
final class Migration {
  const Migration({
    required this.version,
    required this.from,
    required this.to,
    required this.actions,
    this.description,
  });

  factory Migration.parse(String source) {
    final document = loadYaml(source);
    if (document is! Map) {
      throw const KilnException(
        'Migration must contain a map',
        code: 'migration.invalid',
      );
    }
    return Migration.fromMap(_asMap(document));
  }

  factory Migration.fromMap(Map<String, Object?> map) {
    final rawActions = map['actions'];
    return Migration(
      version: map['version'] is int
          ? map['version']! as int
          : int.tryParse('${map['version'] ?? ''}') ?? 1,
      from: '${map['from'] ?? ''}',
      to: '${map['to'] ?? ''}',
      description: map['description'] as String?,
      actions: rawActions is Iterable
          ? rawActions
                .whereType<Map<Object?, Object?>>()
                .map(
                  (action) => MigrationAction.fromMap(<String, Object?>{
                    for (final entry in action.entries)
                      '${entry.key}': entry.value,
                  }),
                )
                .toList(growable: false)
          : const <MigrationAction>[],
    );
  }

  final int version;
  final String from;
  final String to;
  final String? description;
  final List<MigrationAction> actions;

  Map<String, Object?> toJson() => <String, Object?>{
    'version': version,
    'from': from,
    'to': to,
    if (description != null) 'description': description,
    'actions': actions.map((action) => action.toJson()).toList(growable: false),
  };

  static Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': entry.value,
    };
  }
}
