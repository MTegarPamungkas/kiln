import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import 'command_helpers.dart';

/// Lists installed or available extensions.
final class ListCommand extends KilnCommand {
  ListCommand(super.context) {
    argParser
      ..addFlag('installed', negatable: false)
      ..addFlag('available', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List installed or available extensions.';

  @override
  Future<int> run() async {
    final project = optionalProject;
    final flags = <String>[];
    if (argResults!['installed'] == true) {
      flags.add('installed');
    }
    if (argResults!['available'] == true) {
      flags.add('available');
    }
    final showInstalled =
        flags.contains('installed') || (flags.isEmpty && project != null);
    final showAvailable =
        flags.contains('available') || (flags.isEmpty && project == null);
    final json = argResults!['json'] == true;

    final installed = <Map<String, Object?>>[];
    if (showInstalled) {
      if (project == null) {
        if (!json) {
          logger.warn('No Kiln project found in this folder');
        }
      } else {
        for (final entry in project.lockfile.extensions.entries) {
          installed.add(<String, Object?>{
            'id': entry.key,
            'version': entry.value.version,
            'source': entry.value.source.name,
            'files': entry.value.files.length,
          });
        }
      }
    }

    final available = <Map<String, Object?>>[];
    if (showAvailable) {
      for (final extension in extensionCatalog) {
        final manifest = extension.manifest;
        available.add(<String, Object?>{
          'id': manifest.id,
          'name': manifest.name,
          'version': manifest.version,
          'category': manifest.category,
          'tier': manifest.tier.name,
          'provides': manifest.provides,
        });
      }
    }

    if (json) {
      JsonReporter(logger.raw).write(<String, Object?>{
        if (showInstalled) 'installed': installed,
        if (showAvailable) 'available': available,
      });
      return ExitCodes.success;
    }

    if (showInstalled) {
      logger.info('Installed:');
      if (installed.isEmpty) {
        logger.info('  (no extensions yet)');
      }
      for (final item in installed) {
        logger.info(
          '  ${item['id']} ${item['version']} '
          '(${item['source']}, ${item['files']} files)',
        );
      }
    }
    if (showInstalled && showAvailable) {
      logger.blank();
    }
    if (showAvailable) {
      logger.info('Available:');
      for (final item in available) {
        logger.info(
          '  ${item['id']} ${item['version']} '
          '${item['category']} — ${item['name']}',
        );
      }
    }
    return ExitCodes.success;
  }
}
