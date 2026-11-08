import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import '../command_context.dart';
import '../paths.dart';

/// Registry settings resolved from project or global configuration.
final class RegistrySupport {
  RegistrySupport._({
    required this.client,
    required this.cache,
    required this.offline,
  });

  final RegistryClient client;
  final LocalCache cache;
  final bool offline;

  static RegistrySupport? from(
    KilnContext context, {
    Map<String, Object?>? projectConfig,
  }) {
    final projectRegistry = _map(projectConfig?['registry']);
    final url =
        (projectRegistry['url'] as String?) ?? context.globalConfig.registry;
    if (url == null || url.trim().isEmpty) {
      return null;
    }
    final mirror =
        (projectRegistry['mirror'] as String?) ?? context.globalConfig.mirror;
    final offline =
        (projectRegistry['offline'] as bool?) ??
        context.globalConfig.offline;
    final cache = LocalCache(
      Directory(p.join(Paths.globalCache(context.home), 'registry')),
    );
    return RegistrySupport._(
      client: RegistryClient(
        config: RegistryConfig(url: url, mirror: mirror),
        cache: cache,
      ),
      cache: cache,
      offline: offline,
    );
  }

  Future<RegistryIndex> index() {
    return OfflineMode(
      client: client,
      cache: cache,
      offline: offline,
    ).index();
  }

  Future<RegistryPackage> fetch(
    String id,
    RegistryVersion version, {
    Uri? indexUri,
  }) async {
    final bytes = await OfflineMode(
      client: client,
      cache: cache,
      offline: offline,
    ).archive(id, version.version);
    final directory = await Directory.systemTemp.createTemp('kiln_registry_');
    try {
      ArchiveUnpacker().extract(bytes, directory);
      final manifestFile = File(p.join(directory.path, 'extension.yaml'));
      if (!manifestFile.existsSync()) {
        throw const KilnException(
          'Registry archive does not contain extension.yaml.',
          code: 'store.invalid_extension',
        );
      }
      final manifest = ExtensionManifest.parse(
        manifestFile.readAsStringSync(),
        rootPath: directory.path,
      );
      final brick = Directory(p.join(directory.path, 'brick'));
      if (!brick.existsSync()) {
        throw const KilnException(
          'Registry archive does not contain brick/.',
          code: 'store.invalid_extension',
        );
      }
      return RegistryPackage(
        available: AvailableExtension(
          manifest: manifest,
          bundle: createBundle(brick),
          source: ExtensionSource.store,
        ),
        directory: directory,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': entry.value,
    };
  }
}

/// A downloaded extension and the temporary directory it was unpacked into.
final class RegistryPackage {
  const RegistryPackage({required this.available, required this.directory});

  final AvailableExtension available;
  final Directory directory;

  Future<void> dispose() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }
}
