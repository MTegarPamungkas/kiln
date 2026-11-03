import 'package:sembast/sembast.dart';

import 'sembast_local_database.dart';

/// Runs several database operations atomically.
final class TransactionRunner {
  const TransactionRunner();

  Future<T> run<T>(
    SembastLocalDatabase database,
    Future<T> Function(DatabaseClient client) action,
  ) {
    return database.transaction(action);
  }
}
