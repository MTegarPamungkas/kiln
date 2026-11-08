import 'dart:io';

import 'package:args/command_runner.dart';

import 'infra/file_system.dart';
import 'infra/global_config.dart';
import 'infra/kiln_logger.dart';
import 'infra/process_runner.dart';
import 'infra/prompter.dart';
import 'project_context.dart';

/// Dependencies shared by every CLI command.
final class KilnContext {
  const KilnContext({
    required this.cwd,
    required this.logger,
    required this.prompter,
    required this.processRunner,
    required this.fileSystem,
    required this.globalConfig,
    required this.home,
  });

  final Directory cwd;
  final KilnLogger logger;
  final Prompter prompter;
  final ProcessRunner processRunner;
  final FileSystem fileSystem;
  final GlobalConfig globalConfig;

  /// Home directory holding global CLI state (`<home>/.kiln`).
  ///
  /// It is injected rather than read from the environment so that a test never
  /// reads or deletes the developer's real global config and registry cache.
  final String home;
}

/// Base class for a Kiln subcommand.
abstract class KilnCommand extends Command<int> {
  KilnCommand(this.context);

  final KilnContext context;

  KilnLogger get logger => context.logger;

  Prompter get prompter => context.prompter;

  ProcessRunner get processRunner => context.processRunner;

  FileSystem get fileSystem => context.fileSystem;

  ProjectContext? get optionalProject => ProjectContext.find(context.cwd);

  ProjectContext loadProject() => ProjectContext.load(context.cwd);
}
