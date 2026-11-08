import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'command_context.dart';
import 'commands/add_command.dart';
import 'commands/cache_command.dart';
import 'commands/completion_command.dart';
import 'commands/config_command.dart';
import 'commands/create_command.dart';
import 'commands/doctor_command.dart';
import 'commands/ext/ext_command.dart';
import 'commands/graph_command.dart';
import 'commands/info_command.dart';
import 'commands/list_command.dart';
import 'commands/remove_command.dart';
import 'commands/repair_command.dart';
import 'commands/rollback_command.dart';
import 'commands/store_command.dart';
import 'commands/upgrade_command.dart';
import 'commands/version_command.dart';
import 'infra/error_presenter.dart';
import 'infra/exit_codes.dart';
import 'infra/file_system.dart';
import 'infra/global_config.dart';
import 'infra/kiln_logger.dart';
import 'infra/process_runner.dart';
import 'infra/prompter.dart';
import 'paths.dart';

/// The `kiln` command runner.
final class KilnCommandRunner extends CommandRunner<int> {
  KilnCommandRunner(this.context)
    : super(
        'kiln',
        'Generate and evolve Flutter applications with composable extensions.',
      ) {
    argParser
      ..addFlag('verbose', abbr: 'v', negatable: false)
      ..addFlag('quiet', abbr: 'q', negatable: false);

    addCommand(VersionCommand(context));
    addCommand(CreateCommand(context));
    addCommand(AddCommand(context));
    addCommand(RemoveCommand(context));
    addCommand(RepairCommand(context));
    addCommand(ListCommand(context));
    addCommand(InfoCommand(context));
    addCommand(GraphCommand(context));
    addCommand(DoctorCommand(context));
    addCommand(UpgradeCommand(context));
    addCommand(RollbackCommand(context));
    addCommand(ConfigCommand(context));
    addCommand(CacheCommand(context));
    addCommand(StoreCommand(context));
    addCommand(CompletionCommand(context));
    addCommand(ExtCommand(context));
  }

  final KilnContext context;

  KilnLogger get logger => context.logger;

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    logger.configure(
      verbose: topLevelResults['verbose'] == true,
      quiet: topLevelResults['quiet'] == true,
    );
    return super.runCommand(topLevelResults);
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final code = await super.run(args);
      return code ?? ExitCodes.success;
    } on UsageException catch (error) {
      logger.error(error.message);
      logger.info(error.usage);
      return ExitCodes.usage;
    } catch (error, stackTrace) {
      return ErrorPresenter(logger).present(error, stackTrace);
    }
  }
}

/// Builds the CLI runner with overridable dependencies for tests.
KilnCommandRunner buildKilnCommandRunner({
  Directory? cwd,
  KilnLogger? logger,
  Prompter? prompter,
  ProcessRunner? processRunner,
  FileSystem? fileSystem,
  GlobalConfig? globalConfig,
  String? home,
  Future<String?> Function()? corePathDetector,
}) {
  final resolvedHome = home ?? Paths.home();
  return KilnCommandRunner(
    KilnContext(
      cwd: cwd ?? Directory.current,
      logger: logger ?? KilnLogger(),
      prompter: prompter ?? Prompter(interactive: _stdinInteractive()),
      processRunner: processRunner ?? const ProcessRunner(),
      fileSystem: fileSystem ?? const LocalFileSystem(),
      globalConfig:
          globalConfig ?? GlobalConfig.load(Paths.globalConfig(resolvedHome)),
      home: resolvedHome,
      corePathDetector: corePathDetector,
    ),
  );
}

/// Whether stdin can actually carry an interactive prompt. A handle can claim
/// to be a terminal and still fail every console query (no console attached),
/// so the flag is only trusted after one real mode read succeeds.
bool _stdinInteractive() {
  if (!stdin.hasTerminal) {
    return false;
  }
  try {
    return stdin.echoMode;
  } on Object {
    return false;
  }
}
