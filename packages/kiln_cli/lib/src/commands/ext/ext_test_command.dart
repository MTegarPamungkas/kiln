import 'dart:io';

import 'package:path/path.dart' as p;

import '../../command_context.dart';
import '../../infra/exit_codes.dart';
import '../../infra/json_reporter.dart';

/// Runs the extension test suite in the extension folder.
final class ExtTestCommand extends KilnCommand {
  ExtTestCommand(super.context) {
    argParser.addFlag('json', negatable: false);
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run extension tests.';

  @override
  String get invocation => 'kiln ext test [path]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final root = rest.isEmpty
        ? context.cwd
        : Directory(p.join(context.cwd.path, rest.first));
    final packageConfig = File(
      p.join(root.path, '.dart_tool', 'package_config.json'),
    );
    if (!packageConfig.existsSync()) {
      final pubGet = await processRunner.dart(<String>[
        'pub',
        'get',
      ], workingDirectory: root.path);
      if (pubGet.exitCode != 0) {
        if (argResults!['json'] == true) {
          JsonReporter(logger.raw).write(<String, Object?>{
            'exit_code': pubGet.exitCode,
            'stdout': pubGet.stdout,
            'stderr': pubGet.stderr,
          });
        } else {
          logger.error('dart pub get failed at ${root.path}');
          logger.info('${pubGet.stdout}${pubGet.stderr}'.trimRight());
        }
        return ExitCodes.verification;
      }
    }
    final result = await processRunner.dart(<String>[
      'test',
    ], workingDirectory: root.path);

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'exit_code': result.exitCode,
        'stdout': result.stdout,
        'stderr': result.stderr,
      });
    } else {
      if ('${result.stdout}'.isNotEmpty) {
        logger.info('${result.stdout}'.trimRight());
      }
      if ('${result.stderr}'.isNotEmpty) {
        logger.error('${result.stderr}'.trimRight());
      }
    }
    return result.exitCode == 0 ? ExitCodes.success : ExitCodes.verification;
  }
}
