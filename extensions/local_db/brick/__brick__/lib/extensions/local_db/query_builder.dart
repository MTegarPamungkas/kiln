import 'package:kiln_core/kiln_core.dart';
import 'package:sembast/sembast.dart';

/// Converts a [LocalQuery] into a Sembast [Finder].
final class LocalQueryBuilder {
  const LocalQueryBuilder();

  Finder build(LocalQuery? query) {
    final filters = <Filter>[
      for (final entry in (query?.where ?? const <String, Object?>{}).entries)
        Filter.equals(entry.key, entry.value),
    ];
    final orders = <SortOrder>[];
    if (query?.orderBy != null) {
      orders.add(SortOrder(query!.orderBy!, !query.descending));
    }
    return Finder(
      filter: filters.isEmpty
          ? null
          : filters.length == 1
          ? filters.single
          : Filter.and(filters),
      sortOrders: orders,
      limit: query?.limit,
      offset: query?.offset,
    );
  }
}
