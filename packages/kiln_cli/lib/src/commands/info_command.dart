import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import 'command_helpers.dart';

/// Shows everything an extension declares.
final class InfoCommand extends KilnCommand {
  InfoCommand(super.context) {
    argParser.addFlag('json', negatable: false);
  }

  @override
  String get name => 'info';

  @override
  String get description => 'Show an extension manifest.';

  @override
  String get invocation => 'kiln info <extension> [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      usageException('Specify an extension name.');
    }
    final extension = findAvailableExtension(rest.first);
    if (extension == null) {
      throw KilnException(
        'Extension "${rest.first}" not found',
        code: 'catalog.missing',
        suggestion:
            'Available: ${extensionCatalog.map((item) => item.id).join(', ')}',
      );
    }
    final manifest = extension.manifest;

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        ...manifest.toJson(),
        'source': extension.source.name,
      });
      return ExitCodes.success;
    }

    logger.info('${manifest.name} (${manifest.id}) ${manifest.version}');
    logger.info(manifest.description);
    logger.info('Kategori: ${manifest.category} · tier: ${manifest.tier.name}');
    if (manifest.provides.isNotEmpty) {
      logger.info('Provides: ${manifest.provides.join(', ')}');
    }
    if (manifest.requires.isNotEmpty) {
      logger.info('Requires: ${manifest.requires.join(', ')}');
    }
    if (manifest.slots.isNotEmpty) {
      logger.info(
        'Slots: ${manifest.slots.map((slot) => '${slot.name} (${slot.item})').join(', ')}',
      );
    }
    if (manifest.contributions.isNotEmpty) {
      logger.info(
        'Contributes: ${manifest.contributions.map((item) => '${item.slot}@${item.priority}').join(', ')}',
      );
    }
    if (manifest.prompts.isNotEmpty) {
      logger.info('Prompts:');
      for (final prompt in manifest.prompts) {
        final required = prompt.required ? 'wajib' : 'opsional';
        logger.info(
          '  ${prompt.name} (${prompt.type.name}, $required)'
          '${prompt.defaultValue == null ? '' : ' default=${prompt.defaultValue}'}',
        );
      }
    }
    if (manifest.dependencies.isNotEmpty) {
      logger.info(
        'Dependencies: ${manifest.dependencies.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ')}',
      );
    }
    if (manifest.platformSetup.platforms.isNotEmpty) {
      logger.info('Platform: ${manifest.platformSetup.platforms.join(', ')}');
    }
    if (manifest.compatibility.kiln != null) {
      logger.info('Kiln: ${manifest.compatibility.kiln}');
    }
    if (manifest.manualSteps.isNotEmpty) {
      logger.info('Manual steps:');
      for (final step in manifest.manualSteps) {
        logger.info('  - ${step.description}');
      }
    }
    return ExitCodes.success;
  }
}
