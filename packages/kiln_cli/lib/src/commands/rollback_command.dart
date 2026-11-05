import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';

/// Reverts the last completed or interrupted transaction.
final class RollbackCommand extends KilnCommand {
  RollbackCommand(super.context) {
    argParser
      ..addFlag('list', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'rollback';

  @override
  String get description => 'Roll back the last transaction.';

  @override
  Future<int> run() async {
    final project = loadProject();
    const rollback = Rollback();
    final interrupted = rollback.latestInterrupted(project.root);
    final committed = rollback.latestCommitted(project.root);

    if (argResults!['list'] == true) {
      if (argResults!['json'] == true) {
        JsonReporter(logger.raw).write(<String, Object?>{
          'interrupted': interrupted?.id,
          'committed': committed?.id,
        });
      } else {
        logger.info('Interrupted: ${interrupted?.id ?? 'none'}');
        logger.info('Completed: ${committed?.id ?? 'none'}');
      }
      return ExitCodes.success;
    }

    final target = interrupted ?? committed;
    if (target == null) {
      logger.info('No operation to roll back.');
      return ExitCodes.success;
    }

    rollback.run(target);
    logger.success(
      interrupted != null
          ? 'Interrupted operation rolled back.'
          : 'Last operation rolled back.',
    );
    return ExitCodes.success;
  }
}
