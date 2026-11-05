import 'package:kiln_core/kiln_core.dart';
import 'package:sembast/sembast.dart';

import 'query_builder.dart';

/// Builds change streams for a Sembast collection.
final class CollectionWatcher {
  const CollectionWatcher();

  Stream<List<LocalRecord>> watch({
    required Database database,
    required String collection,
    LocalQuery? query,
  }) {
    final store = stringMapStoreFactory.store(collection);
    final finder = const LocalQueryBuilder().build(query);
    return store
        .query(finder: finder)
        .onSnapshots(database)
        .map(toRecords);
  }

  List<LocalRecord> toRecords(
    Iterable<RecordSnapshot<String, Map<String, Object?>>> snapshots,
  ) {
    return <LocalRecord>[
      for (final snapshot in snapshots)
        LocalRecord(
          key: snapshot.key,
          data: Map<String, Object?>.of(snapshot.value),
        ),
    ];
  }
}
