/// What would happen to one file.
enum FileChangeKind { create, overwrite, skip, conflict, delete }

/// One planned file change.
final class FileChange {
  const FileChange(this.path, this.kind);

  final String path;
  final FileChangeKind kind;

  String get label => switch (kind) {
    FileChangeKind.create => 'create',
    FileChangeKind.overwrite => 'overwrite',
    FileChangeKind.skip => 'skip',
    FileChangeKind.conflict => 'conflict',
    FileChangeKind.delete => 'delete',
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    'action': label,
  };
}

/// A complete dry-run report for `kiln add --dry-run` and `--json`.
final class DryRunReport {
  const DryRunReport({
    this.files = const <FileChange>[],
    this.patches = const <String>[],
    this.dependencies = const <String, Object?>{},
    this.devDependencies = const <String, Object?>{},
    this.manualSteps = const <String>[],
    this.warnings = const <String>[],
  });

  final List<FileChange> files;
  final List<String> patches;
  final Map<String, Object?> dependencies;
  final Map<String, Object?> devDependencies;
  final List<String> manualSteps;
  final List<String> warnings;

  bool get hasConflicts =>
      files.any((file) => file.kind == FileChangeKind.conflict);

  String toText() {
    final buffer = StringBuffer();
    for (final file in files) {
      buffer.writeln('  ${file.label.padRight(10)} ${file.path}');
    }
    if (patches.isNotEmpty) {
      buffer.writeln('Native patches:');
      for (final patch in patches) {
        buffer.writeln('  patch      $patch');
      }
    }
    if (dependencies.isNotEmpty) {
      buffer.writeln('Dependencies:');
      for (final entry in dependencies.entries) {
        buffer.writeln('  add        ${entry.key}: ${entry.value}');
      }
    }
    if (devDependencies.isNotEmpty) {
      buffer.writeln('Dev dependencies:');
      for (final entry in devDependencies.entries) {
        buffer.writeln('  add        ${entry.key}: ${entry.value}');
      }
    }
    if (manualSteps.isNotEmpty) {
      buffer.writeln('Manual steps:');
      for (final step in manualSteps) {
        buffer.writeln('  todo       $step');
      }
    }
    for (final warning in warnings) {
      buffer.writeln('  warning    $warning');
    }
    return buffer.toString().trimRight();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'files': files.map((file) => file.toJson()).toList(growable: false),
    'patches': patches,
    'dependencies': dependencies,
    'dev_dependencies': devDependencies,
    'manual_steps': manualSteps,
    'warnings': warnings,
    'has_conflicts': hasConflicts,
  };
}
