import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;

import '../../command_context.dart';
import '../../infra/exit_codes.dart';
import '../../infra/json_reporter.dart';

/// Publishes a packed extension into a local registry directory.
final class ExtPublishCommand extends KilnCommand {
  ExtPublishCommand(super.context) {
    argParser
      ..addOption('registry', help: 'Local registry directory.')
      ..addOption('archive-base-url')
      ..addFlag('dry-run', negatable: false)
      ..addFlag('force', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'publish';

  @override
  String get description => 'Publish an extension to a local registry.';

  @override
  String get invocation => 'kiln ext publish [path] [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final root = rest.isEmpty
        ? context.cwd
        : Directory(p.join(context.cwd.path, rest.first));
    final manifestFile = File(p.join(root.path, 'extension.yaml'));
    if (!manifestFile.existsSync()) {
      throw KilnException(
        'extension.yaml not found at ${root.path}',
        code: 'manifest.missing',
      );
    }
    final manifest = ExtensionManifest.parse(
      manifestFile.readAsStringSync(),
      rootPath: root.path,
    );
    final errors = const ManifestValidator().validate(manifest);
    if (errors.isNotEmpty) {
      throw KilnException(
        'Invalid extension:\n${errors.join('\n')}',
        code: 'manifest.invalid',
      );
    }

    final project = optionalProject;
    final projectRegistry = _registryUrl(project?.config);
    final rawRegistry =
        argResults!['registry'] as String? ??
        projectRegistry ??
        context.globalConfig.registry;
    if (rawRegistry == null || rawRegistry.trim().isEmpty) {
      throw const KilnException(
        'Registry is not configured.',
        code: 'store.not_configured',
        suggestion: 'Add --registry=<folder> or run kiln config --registry=<folder>',
      );
    }
    final registryRoot = _localDirectory(rawRegistry);

    if (argResults!['dry-run'] == true) {
      final bytes = const ArchivePacker().pack(root);
      if (argResults!['json'] == true) {
        JsonReporter(logger.raw).write(<String, Object?>{
          'id': manifest.id,
          'version': manifest.version,
          'registry': registryRoot.path,
          'bytes': bytes.length,
          'dry_run': true,
        });
      } else {
        logger.info(
          'Will publish ${manifest.id} ${manifest.version} '
          '(${bytes.length} bytes) to ${registryRoot.path}',
        );
      }
      return ExitCodes.success;
    }

    final result = await Publisher().publish(
      extensionRoot: root,
      registryRoot: registryRoot,
      archiveBaseUrl: argResults!['archive-base-url'] == null
          ? null
          : Uri.parse(argResults!['archive-base-url'] as String),
      force: argResults!['force'] == true,
    );

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'id': result.id,
        'version': result.version,
        'sha256': result.sha256,
        'archive': result.archivePath,
        'index': result.indexPath,
      });
    } else {
      logger.success(
        'Publish ${result.id} ${result.version} ke ${result.archivePath}',
      );
      logger.info('Index: ${result.indexPath}');
    }
    return ExitCodes.success;
  }

  String? _registryUrl(Map<String, Object?>? config) {
    final registry = config?['registry'];
    if (registry is! Map) {
      return null;
    }
    final url = registry['url'];
    return url is String && url.isNotEmpty ? url : null;
  }

  Directory _localDirectory(String raw) {
    final uri = Uri.parse(raw);
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      throw KilnException(
        'Publish only supports a local folder registry, got "$raw".',
        code: 'store.remote_publish',
        suggestion: 'Publish to a registry folder, then push that folder with Git',
      );
    }
    if (uri.scheme == 'file') {
      return Directory.fromUri(uri);
    }
    return Directory(raw).absolute;
  }
}
