import 'package:sembast/sembast_memory.dart';
import 'package:{{app_name}}/extensions/local_db/sembast_local_database.dart';

var _counter = 0;

Future<SembastLocalDatabase> openTestDatabase() async {
  final database = await databaseFactoryMemory.openDatabase(
    'test_${_counter++}.db',
  );
  return SembastLocalDatabase(database: database);
}
