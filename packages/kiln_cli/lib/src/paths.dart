import 'dart:io';

import 'package:path/path.dart' as p;

/// Paths shared by CLI commands.
abstract final class Paths {
  static String kilnConfig(Directory root) => p.join(root.path, 'kiln.yaml');

  static String lockfile(Directory root) => p.join(root.path, 'kiln.lock.yaml');

  static String kilnDirectory(Directory root) => p.join(root.path, '.kiln');

  static String journalDirectory(Directory root) =>
      p.join(kilnDirectory(root), 'journal');

  static String backupsDirectory(Directory root) =>
      p.join(kilnDirectory(root), 'backups');

  static String globalConfig() {
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    return p.join(home, '.kiln', 'config.yaml');
  }

  static String globalCache() {
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    return p.join(home, '.kiln', 'cache');
  }
}
