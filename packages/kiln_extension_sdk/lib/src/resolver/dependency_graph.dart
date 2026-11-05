import '../manifest/extension_manifest.dart';
import 'capability_index.dart';

/// Reads the requires graph for `kiln graph` and `kiln remove`.
final class DependencyGraph {
  DependencyGraph(Iterable<AvailableExtension> extensions)
    : _byId = <String, AvailableExtension>{
        for (final extension in extensions) extension.id: extension,
      },
      _index = CapabilityIndex(extensions);

  final Map<String, AvailableExtension> _byId;
  final CapabilityIndex _index;

  Set<String> get ids => _byId.keys.toSet();

  AvailableExtension? extension(String id) => _byId[id];

  /// Extensions that transitively require a capability provided by [id].
  Set<String> dependentsOf(String id) {
    final dependents = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final extension in _byId.values) {
        if (extension.id == id || dependents.contains(extension.id)) {
          continue;
        }
        for (final capability in extension.manifest.requires) {
          final provider = _index.singleProviderOf(capability);
          if (provider == null) {
            continue;
          }
          if (provider.id == id || dependents.contains(provider.id)) {
            dependents.add(extension.id);
            changed = true;
            break;
          }
        }
      }
    }
    return dependents;
  }

  /// Dependents first, the requested extension last.
  List<String> removalOrder(String id) {
    final order = dependentsOf(id).toList(growable: false)..sort();
    return <String>[...order, id];
  }

  String toText() {
    final lines = <String>[];
    for (final extension in _sortedExtensions()) {
      final dependencies = <String>{};
      for (final capability in extension.manifest.requires) {
        final provider = _index.singleProviderOf(capability);
        if (provider != null) {
          dependencies.add(provider.id);
        } else {
          dependencies.add('?$capability');
        }
      }
      lines.add(
        '${extension.id} -> ${dependencies.isEmpty ? '(no dependencies)' : dependencies.join(', ')}',
      );
    }
    return lines.join('\n');
  }

  String toMermaid() {
    final buffer = StringBuffer('flowchart TD\n');
    for (final extension in _sortedExtensions()) {
      for (final capability in extension.manifest.requires) {
        final provider = _index.singleProviderOf(capability);
        if (provider == null) {
          buffer.writeln(
            '  ${extension.id} -.-> missing_$capability["?$capability"]',
          );
        } else {
          buffer.writeln('  ${extension.id} --> ${provider.id}');
        }
      }
    }
    return buffer.toString().trimRight();
  }

  List<AvailableExtension> _sortedExtensions() {
    final extensions = _byId.values.toList(growable: false);
    extensions.sort((left, right) => left.id.compareTo(right.id));
    return extensions;
  }
}
