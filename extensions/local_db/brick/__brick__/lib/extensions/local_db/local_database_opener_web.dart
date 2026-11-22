import 'package:kiln_core/kiln_core.dart';
import 'package:sembast_web/sembast_web.dart';

import 'local_db_config.dart';

/// The web has no file path for the browser database.
Future<String?> localDatabasePath(LocalDbConfig config) async => null;

/// Web apps have no cross-process lock; the in-isolate lock covers one tab.
Future<MutationLock?> localDatabaseMutationLock(LocalDbConfig config) async =>
    null;

Future<Database> openLocalDatabase(
  LocalDbConfig config, {
  SembastCodec? codec,
}) {
  return databaseFactoryWeb.openDatabase(config.databaseName, codec: codec);
}
