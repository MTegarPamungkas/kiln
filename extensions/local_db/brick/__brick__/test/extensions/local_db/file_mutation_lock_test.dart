import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/local_db/file_mutation_lock.dart';

void main() {
  test('runs an exclusive action and releases it after an error', () async {
    final directory = await Directory.systemTemp.createTemp('kiln_lock_');
    addTearDown(() => directory.delete(recursive: true));
    final lock = FileMutationLock('${directory.path}/queue.lock');

    expect(await lock.runExclusive(() async => 7), 7);

    await expectLater(
      lock.runExclusive<void>(() async => throw StateError('boom')),
      throwsA(isA<StateError>()),
    );

    // The failed action must not leave the file locked.
    expect(await lock.runExclusive(() async => 'next'), 'next');
    expect(File(lock.path).existsSync(), isTrue);
  });
}
