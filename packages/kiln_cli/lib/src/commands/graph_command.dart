import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import 'command_helpers.dart';

/// Prints the requires graph of installed extensions.
final class GraphCommand extends KilnCommand {
  GraphCommand(super.context) {
    argParser
      ..addOption('format', defaultsTo: 'text', allowed: ['text', 'mermaid'])
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'graph';

  @override
  String get description => 'Print the extension dependency graph.';

  @override
  Future<int> run() async {
    final project = optionalProject;
    final ids =
        project?.lockfile.ids ??
        extensionCatalog.map((extension) => extension.id).toSet();
    final extensions = <AvailableExtension>[
      for (final id in ids)
        if (findAvailableExtension(id) != null) findAvailableExtension(id)!,
    ];
    if (extensions.isEmpty) {
      logger.info('No extensions installed yet.');
      return ExitCodes.success;
    }

    final graph = DependencyGraph(extensions);
    final format = argResults!['format'] as String;
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'format': format,
        'graph': format == 'mermaid' ? graph.toMermaid() : graph.toText(),
      });
      return ExitCodes.success;
    }
    logger.info(format == 'mermaid' ? graph.toMermaid() : graph.toText());
    return ExitCodes.success;
  }
}
