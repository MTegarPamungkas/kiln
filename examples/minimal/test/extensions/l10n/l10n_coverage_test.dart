import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readArb(String locale) {
  final decoded = jsonDecode(
    File('lib/l10n/app_$locale.arb').readAsStringSync(),
  );
  return <String, Object?>{
    for (final entry in (decoded as Map).entries) '${entry.key}': entry.value,
  };
}

Set<String> _messageKeys(Map<String, Object?> arb) {
  return <String>{
    for (final key in arb.keys)
      if (!key.startsWith('@')) key,
  };
}

void main() {
  final english = _readArb('en');
  final indonesian = _readArb('id');

  test('every locale has the same ARB message keys', () {
    final primary = _messageKeys(english);
    expect(primary, isNotEmpty);
    expect(_messageKeys(indonesian), primary);
  });

  test('no ARB message is empty', () {
    for (final arb in <Map<String, Object?>>[english, indonesian]) {
      for (final entry in _messageKeys(arb)) {
        expect(
          '${arb[entry]}'.trim(),
          isNotEmpty,
          reason: 'empty ARB message "$entry"',
        );
      }
    }
  });

  test('plural and placeholder messages keep their metadata', () {
    for (final arb in <Map<String, Object?>>[english, indonesian]) {
      for (final key in const <String>['itemsCount', 'helloName']) {
        expect(arb['@$key'], isA<Map<Object?, Object?>>(), reason: key);
      }
    }
  });

  test('every failure code has an ARB message', () {
    final failureKeys = _messageKeys(english)
        .where(
          (key) =>
              key.startsWith('failure') &&
              key != 'failureTitle' &&
              key != 'failureBody',
        )
        .toList(growable: false);

    expect(failureKeys, isNotEmpty);
    expect(_messageKeys(indonesian), containsAll(failureKeys));
  });
}
