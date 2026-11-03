import 'dart:io';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import '../paths.dart';

/// Lists or clears the registry cache directory.
final class CacheCommand extends KilnCommand {
  CacheCommand(super.context) {
    argParser.addFlag('json', negatable: false);
  }

  @override
  String get name => 'cache';

  @override
  String get description => 'Show or clean the registry cache.';

  @override
  String get invocation => 'kiln cache [clean]';

  @override
  Future<int> run() async {
    final path = Paths.globalCache();
    final clean = argResults!.rest.contains('clean');
    final exists = fileSystem.directoryExists(path);

    if (clean) {
      fileSystem.delete(path);
      logger.success('Cache dibersihkan: $path');
    } else {
      final entries = exists
          ? fileSystem.list(path)
          : const <FileSystemEntity>[];
      logger.info('Cache: $path');
      logger.info(entries.isEmpty ? '  (kosong)' : '  ${entries.length} entri');
    }

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'path': path,
        'cleaned': clean,
        'entries': clean || !exists ? 0 : fileSystem.list(path).length,
      });
    }
    return ExitCodes.success;
  }
}
