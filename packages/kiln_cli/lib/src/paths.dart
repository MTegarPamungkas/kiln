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

  /// The current user's home directory, where global CLI state lives.
  static String home() =>
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.current.path;

  static String globalConfig([String? home]) =>
      p.join(home ?? Paths.home(), '.kiln', 'config.yaml');

  static String globalCache([String? home]) =>
      p.join(home ?? Paths.home(), '.kiln', 'cache');
}
