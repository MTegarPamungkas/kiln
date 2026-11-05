import 'registry_index.dart';

/// Local, offline search over a parsed [RegistryIndex].
final class SearchIndex {
  const SearchIndex(this.index);

  final RegistryIndex index;

  /// Searches id, name, description, and category case-insensitively.
  ///
  /// An empty query returns every extension in registry order.
  List<RegistryExtension> search(String query) => index.search(query);
}
