import 'package:sembast_web/sembast_web.dart';

import 'local_db_config.dart';

Future<Database> openLocalDatabase(
  LocalDbConfig config, {
  SembastCodec? codec,
}) {
  return databaseFactoryWeb.openDatabase(config.databaseName, codec: codec);
}
