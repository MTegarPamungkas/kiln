import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'local_db_config.dart';

Future<Database> openLocalDatabase(
  LocalDbConfig config, {
  SembastCodec? codec,
}) async {
  final path =
      config.path ??
      p.join(
        (await getApplicationDocumentsDirectory()).path,
        config.databaseName,
      );
  await Directory(p.dirname(path)).create(recursive: true);
  return databaseFactoryIo.openDatabase(path, codec: codec);
}
