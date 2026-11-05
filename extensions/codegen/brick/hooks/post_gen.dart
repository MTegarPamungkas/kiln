import 'dart:io';

import 'package:mason/mason.dart';

/// Runs `build_runner` after the templates land so the sample model is generated
/// immediately. Failure is only a warning: the files are still installed and the
/// user can run `dart run build_runner build` themselves.
Future<void> postGenerate(FileContext context) async {
  final logger = Logger();
  logger.info('Running build_runner for the codegen extension...');
  try {
    final result = await Process.run(
      'dart',
      const ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      runInShell: Platform.isWindows,
    );
    if (result.exitCode == 0) {
      logger.info('Code generation complete.');
    } else {
      logger.warn(
        'build_runner did not finish cleanly. Run '
        '`dart run build_runner build` manually.\n${result.stderr}',
      );
    }
  } on ProcessException catch (error) {
    logger.warn(
      'Could not start build_runner (${error.message}). '
      'Run `dart pub get` then `dart run build_runner build`.',
    );
  }
}
