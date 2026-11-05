import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:path/path.dart' as p;
import 'package:{{app_name}}/extensions/local_db/local_database_support.dart';
import 'package:{{app_name}}/extensions/local_db/local_db_config.dart';

void main() {
  test('explicit database paths are supported', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_local_db_');
    addTearDown(() => directory.delete(recursive: true));
    final support = LocalDatabaseSupport(
      config: LocalDbConfig(path: p.join(directory.path, 'app.db')),
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['backend'], 'sembast_io');
  });

  test('caches the probe until cleared', () async {
    var calls = 0;
    final support = LocalDatabaseSupport(
      config: const LocalDbConfig(path: 'app.db'),
      probe: (config) async {
        calls++;
        return const SupportInfo.supported();
      },
    );

    await support.check();
    await support.check();
    expect(calls, 1);

    support.clear();
    await support.check();
    expect(calls, 2);
  });

  test('converts probe failures into unavailable info', () async {
    final support = LocalDatabaseSupport(
      config: const LocalDbConfig(),
      probe: (config) async => throw StateError('no document directory'),
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });
}
