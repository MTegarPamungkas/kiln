import 'package:pub_semver/pub_semver.dart';

import 'registry_index.dart';

/// Picks the highest extension version compatible with the host project.
final class VersionResolver {
  const VersionResolver();

  /// Selects a version of [extension] that:
  ///
  /// * parses as semver,
  /// * is not a prerelease unless [allowPrerelease] is set,
  /// * satisfies the Kiln constraint and the supplied Dart and Flutter versions,
  /// * matches [requestedVersion] and provides [capability], when supplied,
  /// * is greater than [installedVersion] when one is installed.
  ///
  /// A missing constraint is treated as compatible. Returns `null` when no
  /// version qualifies.
  RegistryVersion? resolve(
    RegistryExtension extension, {
    required Version kilnVersion,
    String? installedVersion,
    Version? dartVersion,
    Version? flutterVersion,
    String? requestedVersion,
    String? capability,
    bool allowPrerelease = false,
  }) {
    final installed = installedVersion == null
        ? null
        : _tryParseVersion(installedVersion);
    RegistryVersion? best;
    Version? bestVersion;

    for (final candidate in extension.versions) {
      if (requestedVersion != null && candidate.version != requestedVersion) {
        continue;
      }
      if (capability != null && !candidate.provides.contains(capability)) {
        continue;
      }
      final version = _tryParseVersion(candidate.version);
      if (version == null) {
        continue;
      }
      if (!allowPrerelease && version.isPreRelease) {
        continue;
      }
      if (installed != null && version <= installed) {
        continue;
      }
      if (!_allows(candidate.compatibility['kiln'], kilnVersion)) {
        continue;
      }
      if (dartVersion != null &&
          !_allows(candidate.compatibility['dart'], dartVersion)) {
        continue;
      }
      if (flutterVersion != null &&
          !_allows(candidate.compatibility['flutter'], flutterVersion)) {
        continue;
      }
      if (bestVersion == null || version > bestVersion) {
        best = candidate;
        bestVersion = version;
      }
    }
    return best;
  }

  static Version? _tryParseVersion(String source) {
    try {
      return Version.parse(source);
    } on FormatException {
      return null;
    }
  }

  static bool _allows(String? constraintSource, Version version) {
    if (constraintSource == null || constraintSource.trim().isEmpty) {
      return true;
    }
    try {
      return VersionConstraint.parse(constraintSource).allows(version);
    } on FormatException {
      return false;
    }
  }
}
