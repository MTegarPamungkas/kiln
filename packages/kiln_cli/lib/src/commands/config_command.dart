import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/global_config.dart';
import '../infra/json_reporter.dart';
import '../paths.dart';

/// Reads and writes registry configuration.
final class ConfigCommand extends KilnCommand {
  ConfigCommand(super.context) {
    argParser
      ..addOption('registry')
      ..addOption('mirror')
      ..addFlag('offline', negatable: true)
      ..addFlag('global', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'config';

  @override
  String get description => 'Read or write registry configuration.';

  @override
  Future<int> run() async {
    final global = argResults!['global'] == true;
    final hasChanges =
        argResults!.wasParsed('registry') ||
        argResults!.wasParsed('mirror') ||
        argResults!.wasParsed('offline');

    if (global) {
      var config = context.globalConfig;
      if (hasChanges) {
        config = GlobalConfig(
          registry: argResults!.wasParsed('registry')
              ? argResults!['registry'] as String?
              : config.registry,
          mirror: argResults!.wasParsed('mirror')
              ? argResults!['mirror'] as String?
              : config.mirror,
          offline: argResults!.wasParsed('offline')
              ? argResults!['offline'] == true
              : config.offline,
        );
        config.save();
      }
      return _print(config, argResults!['json'] == true);
    }

    final project = loadProject();
    final registry = _asMap(project.config['registry']);
    if (hasChanges) {
      final editor = YamlEditor(project.configFile.readAsStringSync());
      var root = editor.parseAt(<Object>[]);
      if (root is! YamlMap) {
        editor.update(<Object>[], <String, Object?>{});
        root = editor.parseAt(<Object>[]);
      }
      if (root is YamlMap && !root.containsKey('registry')) {
        editor.update(<Object>['registry'], <String, Object?>{});
      }
      if (argResults!.wasParsed('registry')) {
        editor.update(<Object>['registry', 'url'], argResults!['registry']);
      }
      if (argResults!.wasParsed('mirror')) {
        editor.update(<Object>['registry', 'mirror'], argResults!['mirror']);
      }
      if (argResults!.wasParsed('offline')) {
        editor.update(<Object>['registry', 'offline'], argResults!['offline']);
      }
      project.configFile.writeAsStringSync(editor.toString());
      registry
        ..['url'] = argResults!.wasParsed('registry')
            ? argResults!['registry']
            : registry['url']
        ..['mirror'] = argResults!.wasParsed('mirror')
            ? argResults!['mirror']
            : registry['mirror']
        ..['offline'] = argResults!.wasParsed('offline')
            ? argResults!['offline']
            : registry['offline'];
    }
    return _print(
      GlobalConfig(
        registry: registry['url'] as String?,
        mirror: registry['mirror'] as String?,
        offline: registry['offline'] == true,
      ),
      argResults!['json'] == true,
    );
  }

  int _print(GlobalConfig config, bool json) {
    if (json) {
      JsonReporter(logger.raw).write(config.toJson());
    } else {
      logger.info('registry: ${config.registry ?? '(bundled)'}');
      logger.info('mirror: ${config.mirror ?? '(none)'}');
      logger.info('offline: ${config.offline}');
      logger.detail('File global: ${Paths.globalConfig()}');
    }
    return ExitCodes.success;
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) {
      return <String, Object?>{};
    }
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': entry.value,
    };
  }
}
