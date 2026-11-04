import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/storage/typed_key.dart';

import 'test_support.dart';

void main() {
  final storage = createTestStorage();
  const enabled = StorageKey<bool>(
    name: 'enabled',
    encode: _identity,
    decode: _asBool,
    defaultValue: true,
  );

  test('uses the default for a missing key', () async {
    expect(await enabled.read(storage), isTrue);
  });

  test('writes and reads a typed value', () async {
    await enabled.write(storage, false);

    expect(await enabled.read(storage), isFalse);

    await enabled.delete(storage);
    expect(await enabled.read(storage), isTrue);
  });

  test('maps a corrupt stored value to a storage Failure', () async {
    final storage = createTestStorage();
    await storage.write('enabled', 'not a json bool');

    await expectLater(
      enabled.read(storage),
      throwsA(isA<Failure>()),
    );
  });
}

Object? _identity(Object? value) => value;

bool _asBool(Object? value) => value! as bool;
