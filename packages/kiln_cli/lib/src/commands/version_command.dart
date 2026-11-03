import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import '../infra/update_checker.dart';
import '../version.dart';

final class VersionCommand extends KilnCommand {
  VersionCommand(super.context) {
    argParser
      ..addFlag('json', negatable: false, help: 'Print JSON.')
      ..addFlag(
        'check-updates',
        negatable: false,
        help: 'Check pub.dev for a newer CLI release.',
      );
  }

  @override
  String get name => 'version';

  @override
  String get description => 'Show the CLI and kiln_core versions.';

  @override
  Future<int> run() async {
    final json = argResults?['json'] == true;
    final checkUpdates = argResults?['check-updates'] == true;
    final latest = checkUpdates ? await const UpdateChecker().check() : null;

    if (json) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'kiln': kilnVersion,
        'core': kilnCoreVersion,
        'latest': ?latest,
      });
    } else {
      logger.info('kiln $kilnVersion');
      logger.info('kiln_core $kilnCoreVersion');
      if (latest != null) {
        logger.info('Versi baru tersedia: $latest');
      }
    }
    return ExitCodes.success;
  }
}
