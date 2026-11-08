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
    final path = Paths.globalCache(context.home);
    final clean = argResults!.rest.contains('clean');
    final json = argResults!['json'] == true;
    final exists = fileSystem.directoryExists(path);
    final entries = !clean && exists
        ? fileSystem.list(path)
        : const <FileSystemEntity>[];

    if (clean) {
      fileSystem.delete(path);
    }

    // `--json` is machine output: emitting the human lines as well would break
    // every caller that pipes the result into a JSON parser.
    if (json) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'path': path,
        'cleaned': clean,
        'entries': entries.length,
      });
      return ExitCodes.success;
    }

    if (clean) {
      logger.success('Cache cleaned: $path');
    } else {
      logger.info('Cache: $path');
      logger.info(entries.isEmpty ? '  (empty)' : '  ${entries.length} entries');
    }
    return ExitCodes.success;
  }
}
