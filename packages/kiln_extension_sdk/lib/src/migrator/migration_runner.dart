import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml_edit/yaml_edit.dart';

import '../installer/pubspec_writer.dart';
import '../installer/transaction/transaction.dart';
import 'migration.dart';
import 'migration_actions.dart';

/// What a migration run changed.
final class MigrationResult {
  const MigrationResult({required this.applied, required this.messages});

  final List<String> applied;
  final List<String> messages;
}

/// Runs migrations inside one transaction.
final class MigrationRunner {
  const MigrationRunner();

  MigrationResult run({
    required Directory projectRoot,
    required List<Migration> migrations,
  }) {
    final applied = <String>[];
    final messages = <String>[];
    final transaction = Transaction.begin(projectRoot);
    try {
      for (final migration in migrations) {
        for (final action in migration.actions) {
          _apply(
            action: action,
            projectRoot: projectRoot,
            transaction: transaction,
            messages: messages,
          );
        }
        applied.add('${migration.from} -> ${migration.to}');
      }
      transaction.commit();
    } catch (_) {
      transaction.rollback();
      rethrow;
    }
    return MigrationResult(
      applied: List<String>.unmodifiable(applied),
      messages: List<String>.unmodifiable(messages),
    );
  }

  void _apply({
    required MigrationAction action,
    required Directory projectRoot,
    required Transaction transaction,
    required List<String> messages,
  }) {
    switch (action) {
      case RenameFileAction():
        transaction.renameFile(action.from, action.to);
      case DeleteFileAction():
        transaction.deleteFile(action.path);
      case ReplaceDependencyAction():
        final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
        if (!pubspec.existsSync()) {
          return;
        }
        final writer = PubspecWriter(pubspec);
        transaction.writeText(
          'pubspec.yaml',
          writer.editedWithDependency(
            pubspec.readAsStringSync(),
            action.name,
            action.version,
          ),
        );
      case UpdateConfigAction():
        final config = File(p.join(projectRoot.path, 'kiln.yaml'));
        if (!config.existsSync()) {
          return;
        }
        final editor = YamlEditor(config.readAsStringSync());
        editor.update(action.key.split('.'), action.value);
        transaction.writeText('kiln.yaml', editor.toString());
      case MessageAction():
        messages.add(action.text);
    }
  }
}
