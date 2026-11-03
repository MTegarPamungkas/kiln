import 'package:pub_semver/pub_semver.dart';

import '../manifest/extension_manifest.dart';

/// One extension that can move to a newer version.
final class UpgradeCandidate {
  const UpgradeCandidate({
    required this.id,
    required this.from,
    required this.to,
    required this.available,
  });

  final String id;
  final String from;
  final String to;
  final AvailableExtension available;

  @override
  String toString() => '$id $from -> $to';
}

/// Chooses the highest available version for extensions that are installed.
final class UpgradePlanner {
  UpgradePlanner({required Iterable<AvailableExtension> available})
    : _available = <String, AvailableExtension>{
        for (final extension in available) extension.id: extension,
      };

  final Map<String, AvailableExtension> _available;

  List<UpgradeCandidate> plan({
    required Map<String, String> installedVersions,
    Set<String>? only,
    bool all = true,
  }) {
    final candidates = <UpgradeCandidate>[];
    for (final entry in installedVersions.entries) {
      if (!all && only != null && !only.contains(entry.key)) {
        continue;
      }
      final available = _available[entry.key];
      if (available == null) {
        continue;
      }
      try {
        final from = Version.parse(entry.value);
        final to = Version.parse(available.manifest.version);
        if (to > from) {
          candidates.add(
            UpgradeCandidate(
              id: entry.key,
              from: entry.value,
              to: available.manifest.version,
              available: available,
            ),
          );
        }
      } catch (_) {
        continue;
      }
    }
    candidates.sort((left, right) => left.id.compareTo(right.id));
    return candidates;
  }
}
