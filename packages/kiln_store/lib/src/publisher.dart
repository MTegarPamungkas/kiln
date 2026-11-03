import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'archive_packer.dart';
import 'checksum_verifier.dart';
import 'kiln_store_exception.dart';
import 'registry_index.dart';

/// Result of publishing one extension version.
final class PublishResult {
  const PublishResult({
    required this.id,
    required this.version,
    required this.sha256,
    required this.archivePath,
    required this.indexPath,
  });

  final String id;
  final String version;
  final String sha256;
  final String archivePath;
  final String indexPath;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'version': version,
    'sha256': sha256,
    'archive': archivePath,
    'index': indexPath,
  };
}

/// Validates an extension and publishes a version into a local registry.
final class Publisher {
  Publisher({ArchivePacker? packer, ManifestValidator? validator})
    : _packer = packer ?? const ArchivePacker(),
      _validator = validator ?? const ManifestValidator();

  final ArchivePacker _packer;
  final ManifestValidator _validator;

  /// Packs [extensionRoot], writes `archives/<id>-<version>.tgz`, and updates
  /// `registryRoot/index.json`.
  ///
  /// A duplicate version is refused unless [force] is true, in which case the
  /// archive and index entry are replaced. Other extensions and versions are
  /// preserved, extensions are sorted by id and versions by ascending semver.
  Future<PublishResult> publish({
    required Directory extensionRoot,
    required Directory registryRoot,
    Uri? archiveBaseUrl,
    bool force = false,
  }) async {
    final manifestFile = File(p.join(extensionRoot.path, 'extension.yaml'));
    if (!manifestFile.existsSync()) {
      throw KilnStoreException(
        'extension.yaml was not found in ${extensionRoot.path}.',
        code: 'store.manifest_missing',
      );
    }
    final ExtensionManifest manifest;
    try {
      manifest = ExtensionManifest.parse(
        manifestFile.readAsStringSync(),
        rootPath: extensionRoot.path,
      );
    } on KilnException catch (error) {
      throw KilnStoreException(
        error.message,
        code: error.code,
        suggestion: error.suggestion,
        details: error.details,
      );
    }
    _validator.throwIfInvalid(manifest);

    final indexFile = File(p.join(registryRoot.path, 'index.json'));
    final existing = indexFile.existsSync()
        ? RegistryIndex.parse(indexFile.readAsStringSync())
        : RegistryIndex(
            generatedAt: DateTime.now().toUtc(),
            extensions: const <RegistryExtension>[],
          );
    final previous = existing.find(manifest.id);
    final isDuplicate = previous?.findVersion(manifest.version) != null;
    if (isDuplicate && !force) {
      throw KilnStoreException(
        '${manifest.id} ${manifest.version} is already published.',
        code: 'store.duplicate_version',
        suggestion: 'Bump the version or publish with force to replace it.',
        details: <String, Object?>{
          'id': manifest.id,
          'version': manifest.version,
        },
      );
    }

    final archiveBytes = _packer.pack(extensionRoot);
    final digest = sha256Hex(archiveBytes);
    final relativeArchive = 'archives/${manifest.id}-${manifest.version}.tgz';
    final archiveFile = File(
      p.joinAll(<String>[registryRoot.path, ...relativeArchive.split('/')]),
    );
    archiveFile.parent.createSync(recursive: true);
    archiveFile.writeAsBytesSync(archiveBytes);

    final archiveUrl = archiveBaseUrl == null
        ? relativeArchive
        : _joinBase(archiveBaseUrl, relativeArchive);
    final compatibility = <String, String>{
      if (manifest.compatibility.kiln != null)
        'kiln': manifest.compatibility.kiln!,
      if (manifest.compatibility.dart != null)
        'dart': manifest.compatibility.dart!,
      if (manifest.compatibility.flutter != null)
        'flutter': manifest.compatibility.flutter!,
    };
    final published = RegistryVersion(
      version: manifest.version,
      url: archiveUrl,
      sha256: digest,
      requires: manifest.requires,
      provides: manifest.provides,
      compatibility: compatibility,
    );

    final versions = <RegistryVersion>[
      ...?previous?.versions.where(
        (version) => version.version != manifest.version,
      ),
      published,
    ]..sort((left, right) => _compareVersions(left.version, right.version));
    var latest = versions.first.version;
    for (final version in versions.skip(1)) {
      if (_compareVersions(version.version, latest) > 0) {
        latest = version.version;
      }
    }

    final extensions = <RegistryExtension>[
      ...existing.extensions.where((extension) => extension.id != manifest.id),
      RegistryExtension(
        id: manifest.id,
        name: manifest.name,
        description: manifest.description,
        category: manifest.category,
        latest: latest,
        tier: manifest.tier,
        versions: versions,
      ),
    ]..sort((left, right) => left.id.compareTo(right.id));

    final next = RegistryIndex(
      generatedAt: DateTime.now().toUtc(),
      extensions: extensions,
    );
    indexFile.parent.createSync(recursive: true);
    indexFile.writeAsStringSync(next.encode());

    return PublishResult(
      id: manifest.id,
      version: manifest.version,
      sha256: digest,
      archivePath: archiveFile.path,
      indexPath: indexFile.path,
    );
  }

  static String _joinBase(Uri base, String relative) {
    final text = base.toString();
    final directory = text.endsWith('/') ? base : Uri.parse('$text/');
    return directory.resolve(relative).toString();
  }

  static int _compareVersions(String left, String right) {
    final leftVersion = _tryParseVersion(left);
    final rightVersion = _tryParseVersion(right);
    if (leftVersion != null && rightVersion != null) {
      return leftVersion.compareTo(rightVersion);
    }
    return left.compareTo(right);
  }

  static Version? _tryParseVersion(String source) {
    try {
      return Version.parse(source);
    } on FormatException {
      return null;
    }
  }
}
