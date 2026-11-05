import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../kiln_exception.dart';
import 'migration.dart';

/// Reads migration files from an extension folder.
final class MigrationLoader {
  const MigrationLoader();

  List<Migration> load(Directory extensionRoot) {
    final directory = Directory(p.join(extensionRoot.path, 'migrations'));
    if (!directory.existsSync()) {
      return const <Migration>[];
    }
    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (file) => file.path.endsWith('.yaml') || file.path.endsWith('.yml'),
        )
        .toList(growable: false);
    final migrations = <Migration>[];
    for (final file in files) {
      try {
        migrations.add(Migration.parse(file.readAsStringSync()));
      } catch (error) {
        throw KilnException(
          'Cannot read migration ${p.basename(file.path)}: $error',
          code: 'migration.invalid',
        );
      }
    }
    migrations.sort((left, right) => left.version.compareTo(right.version));
    return List<Migration>.unmodifiable(migrations);
  }

  /// Selects migrations that move [installed] toward [target].
  List<Migration> select({
    required List<Migration> migrations,
    required String installed,
    required String target,
  }) {
    final from = Version.parse(installed);
    final to = Version.parse(target);
    return migrations
        .where((migration) {
          try {
            final migrationFrom = Version.parse(migration.from);
            final migrationTo = Version.parse(migration.to);
            return migrationFrom >= from && migrationTo <= to;
          } catch (_) {
            return false;
          }
        })
        .toList(growable: false);
  }
}
