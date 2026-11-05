/// One out-of-band hint that rows changed somewhere in the database.
final class NeonChangeHint {
  const NeonChangeHint({this.table, this.id});

  /// The table that changed, or null for every table.
  final String? table;

  /// The row id that changed, or null for every row in [table].
  final String? id;
}

/// Push source of [NeonChangeHint]s the app feeds from an out-of-band channel
/// — a push notification, socket, or webhook relay — because the Neon Data API
/// offers no subscribe channel of its own.
///
/// `RemoteDatabase.watch` re-polls a row as soon as a matching hint arrives,
/// instead of waiting for the next [NeonConfig.watchInterval] tick. Hints are
/// best-effort: a missed hint only means the watch refreshes on the interval
/// as before.
abstract interface class NeonChangeSignal {
  Stream<NeonChangeHint> get changes;
}
