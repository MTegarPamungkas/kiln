import 'dart:convert';
import 'dart:io';

import 'root_path.dart';

/// State of an installation transaction.
enum JournalStatus { running, committed }

/// One reversible file operation.
enum JournalOperationType { write, delete }

/// A single operation recorded before it is applied.
final class JournalOperation {
  const JournalOperation({
    required this.type,
    required this.path,
    required this.existed,
  });

  final JournalOperationType type;
  final String path;
  final bool existed;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.name,
    'path': path,
    'existed': existed,
  };

  static JournalOperation fromJson(Map<String, Object?> json) {
    return JournalOperation(
      type: '${json['type']}' == 'delete'
          ? JournalOperationType.delete
          : JournalOperationType.write,
      path: '${json['path'] ?? ''}',
      existed: json['existed'] == true,
    );
  }
}

/// Records every file operation so an interrupted or completed transaction
/// can be reversed.
final class Journal {
  Journal({
    required this.id,
    required this.projectRoot,
    required this.startedAt,
    List<JournalOperation> operations = const <JournalOperation>[],
    this.status = JournalStatus.running,
  }) : operations = <JournalOperation>[...operations];

  factory Journal.create(Directory projectRoot) {
    return Journal(
      id: DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
      projectRoot: projectRoot,
      startedAt: DateTime.now().toUtc(),
    );
  }

  final String id;
  final Directory projectRoot;
  final DateTime startedAt;
  final List<JournalOperation> operations;
  JournalStatus status;

  File get file {
    RootPath.validateId(id);
    return File(RootPath(projectRoot).resolve('.kiln/journal/$id.json'));
  }

  void add(JournalOperation operation) {
    operations.add(operation);
    save();
  }

  void save() {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(toJson()));
  }

  void markCommitted() {
    status = JournalStatus.committed;
    save();
  }

  void deleteFile() {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'started_at': startedAt.toIso8601String(),
    'status': status.name,
    'operations': operations
        .map((operation) => operation.toJson())
        .toList(growable: false),
  };

  static Journal fromJson(
    Map<String, Object?> json, {
    required Directory projectRoot,
  }) {
    final rawOperations = json['operations'];
    return Journal(
      id: '${json['id'] ?? ''}',
      projectRoot: projectRoot,
      startedAt:
          DateTime.tryParse('${json['started_at'] ?? ''}') ??
          DateTime.now().toUtc(),
      status: '${json['status']}' == 'committed'
          ? JournalStatus.committed
          : JournalStatus.running,
      operations: rawOperations is Iterable
          ? rawOperations
                .whereType<Map<Object?, Object?>>()
                .map(
                  (operation) => JournalOperation.fromJson(<String, Object?>{
                    for (final entry in operation.entries)
                      '${entry.key}': entry.value,
                  }),
                )
                .toList(growable: false)
          : const <JournalOperation>[],
    );
  }

  static Journal fromFile(File file, {required Directory projectRoot}) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Journal must contain a JSON object');
    }
    return Journal.fromJson(<String, Object?>{
      for (final entry in decoded.entries) '${entry.key}': entry.value,
    }, projectRoot: projectRoot);
  }

  static Journal? latest(Directory projectRoot, {JournalStatus? status}) {
    final directory = Directory(RootPath(projectRoot).resolve('.kiln/journal'));
    if (!directory.existsSync()) {
      return null;
    }
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList(growable: false)
          ..sort(
            (left, right) =>
                right.lastModifiedSync().compareTo(left.lastModifiedSync()),
          );
    for (final file in files) {
      try {
        final journal = Journal.fromFile(file, projectRoot: projectRoot);
        if (status == null || journal.status == status) {
          return journal;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
