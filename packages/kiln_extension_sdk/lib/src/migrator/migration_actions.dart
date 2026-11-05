import '../kiln_exception.dart';

/// One reversible change in an extension migration.
sealed class MigrationAction {
  const MigrationAction();

  Map<String, Object?> toJson();

  static MigrationAction fromMap(Map<String, Object?> map) {
    return switch ('${map['type']}') {
      'rename_file' => RenameFileAction(
        from: '${map['from'] ?? ''}',
        to: '${map['to'] ?? ''}',
      ),
      'delete_file' => DeleteFileAction('${map['path'] ?? ''}'),
      'replace_dependency' => ReplaceDependencyAction(
        name: '${map['name'] ?? ''}',
        version: '${map['version'] ?? ''}',
      ),
      'update_config' => UpdateConfigAction(
        key: '${map['key'] ?? ''}',
        value: map['value'],
      ),
      'message' => MessageAction('${map['text'] ?? ''}'),
      _ => throw KilnException(
        'Unknown migration action "${map['type']}"',
        code: 'migration.unknown_action',
      ),
    };
  }
}

/// Renames a project file.
final class RenameFileAction extends MigrationAction {
  const RenameFileAction({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'rename_file',
    'from': from,
    'to': to,
  };
}

/// Deletes a project file.
final class DeleteFileAction extends MigrationAction {
  const DeleteFileAction(this.path);

  final String path;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'delete_file',
    'path': path,
  };
}

/// Replaces the version constraint of one dependency.
final class ReplaceDependencyAction extends MigrationAction {
  const ReplaceDependencyAction({required this.name, required this.version});

  final String name;
  final String version;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'replace_dependency',
    'name': name,
    'version': version,
  };
}

/// Updates one key in `kiln.yaml`.
final class UpdateConfigAction extends MigrationAction {
  const UpdateConfigAction({required this.key, this.value});

  final String key;
  final Object? value;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'update_config',
    'key': key,
    'value': value,
  };
}

/// Prints a message to the user during migration.
final class MessageAction extends MigrationAction {
  const MessageAction(this.text);

  final String text;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'message',
    'text': text,
  };
}
