import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';

import '../command_context.dart';
import '../commands/command_helpers.dart';
import '../project_context.dart';
import 'host_compatibility.dart';
import 'registry_support.dart';

/// Resolves installed registry entries from their exact version and archive.
final class ProjectCatalog {
  ProjectCatalog(KilnContext context, this.project)
    : registry = RegistrySupport.from(context, projectConfig: project.config);

  final ProjectContext project;
  final RegistrySupport? registry;
  Future<RegistryIndex>? _index;
  final _installed = <String, Future<AvailableExtension?>>{};

  Future<AvailableExtension?> installed(String id) =>
      _installed.putIfAbsent(id, () => _loadInstalled(id));

  Future<List<AvailableExtension>> available({
    Map<String, AvailableExtension> replacements = const {},
    bool requireExact = true,
  }) async {
    final catalog = {
      for (final extension in extensionCatalog) extension.id: extension,
    };
    for (final entry in project.lockfile.extensions.entries) {
      if (replacements.containsKey(entry.key)) continue;
      final extension = await installed(entry.key);
      if (extension == null) continue;
      if (requireExact && extension.manifest.version != entry.value.version) {
        throw KilnException(
          'Metadata for installed ${entry.key} ${entry.value.version} is unavailable.',
          code: 'extension.locked_metadata',
          suggestion: 'Use a matching CLI or registry, or upgrade the installed extension.',
        );
      }
      catalog[entry.key] = extension;
    }
    return {...catalog, ...replacements}.values.toList(growable: false);
  }

  Future<List<AvailableExtension>> withRegistryDependencies(
    AvailableExtension root,
    RegistryIndex index,
    HostCompatibility host,
  ) async {
    final entries = await available(replacements: {root.id: root});
    final catalog = {for (final extension in entries) extension.id: extension};
    final pending = [root];
    final visited = <String>{};
    final installedIds = {...project.lockfile.ids, root.id};
    while (pending.isNotEmpty) {
      final extension = pending.removeLast();
      if (!visited.add(extension.id)) continue;
      for (final capability in extension.manifest.requires) {
        if (capability == 'app_basic') continue;
        final known = catalog.values
            .where(
              (candidate) => candidate.manifest.provides.contains(capability),
            )
            .toList();
        final selected = known.where(
          (candidate) => installedIds.contains(candidate.id),
        );
        final preferred =
            selected.firstOrNull ?? (known.length == 1 ? known.single : null);
        if (preferred != null) {
          pending.add(preferred);
        }
        if (known.isNotEmpty) continue;

        final candidates = <(String, RegistryVersion)>[];
        for (final entry in index.extensions) {
          if (installedIds.contains(entry.id) ||
              !entry.versions.any(
                (version) => version.provides.contains(capability),
              )) {
            continue;
          }
          final version = await host.select(entry, capability: capability);
          if (version != null) candidates.add((entry.id, version));
        }
        if (candidates.length > 1) {
          throw KilnException(
            'Multiple registry extensions provide "$capability": '
            '${candidates.map((candidate) => candidate.$1).join(', ')}.',
            code: 'store.ambiguous_provider',
            suggestion: 'Install the desired provider explicitly.',
          );
        }
        if (candidates.isEmpty) continue;
        final (id, version) = candidates.single;
        final package = await registry!.fetch(id, version);
        try {
          catalog[id] = package.available;
          pending.add(package.available);
        } finally {
          await package.dispose();
        }
      }
    }
    return catalog.values.toList(growable: false);
  }

  Future<AvailableExtension?> _loadInstalled(String id) async {
    final lock = project.lockfile.extensions[id];
    final bundled = findAvailableExtension(id);
    if (lock == null) return bundled;
    final support = registry;
    if (lock.source == ExtensionSource.bundled &&
        (bundled?.manifest.version == lock.version || support == null)) {
      return bundled;
    }
    final artifact = lock.artifact;
    if (support == null ||
        (artifact != null && support.identity != artifact.registry)) {
      throw KilnException(
        'The registry for "$id" ${lock.version} is unavailable.',
        code: 'store.locked_registry',
        suggestion: 'Configure the registry used to install this extension.',
      );
    }
    final index = await (_index ??= support.index());
    final version = index.find(id)?.findVersion(lock.version);
    if (version == null && lock.source == ExtensionSource.bundled) {
      return bundled;
    }
    if (version == null ||
        (artifact != null && version.sha256 != artifact.sha256)) {
      throw KilnException(
        'The registry does not have the locked artifact for "$id" ${lock.version}.',
        code: 'store.locked_artifact',
        suggestion: 'Restore the original registry index and archive.',
      );
    }
    final package = await support.fetch(id, version);
    try {
      final available = package.available;
      return AvailableExtension(
        manifest: available.manifest,
        bundle: available.bundle,
        docs: available.docs,
        source: lock.source,
        artifact: lock.source == ExtensionSource.store
            ? available.artifact
            : null,
      );
    } finally {
      await package.dispose();
    }
  }
}
