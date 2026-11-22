import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/secure_storage/first_run_wipe.dart';

import 'test_support.dart';

void main() {
  test('wipes owned Keychain leftovers only on the first iOS run', () async {
    final gateway = FakeSecureStorageGateway()
      ..values['app.old.key'] = 'old';
    final storage = InMemoryStorage();
    final wipe = FirstRunWipe(
      gateway: gateway,
      storage: storage,
      prefix: 'app.',
    );

    expect(await wipe.run(isIOS: false), isFalse);
    expect(gateway.values, isNotEmpty);

    expect(await wipe.run(isIOS: true), isTrue);
    expect(gateway.values, isEmpty);
    expect(await storage.read('secure_storage.first_run_wiped'), 'true');

    gateway.values['app.new.key'] = 'new';
    expect(await wipe.run(isIOS: true), isFalse);
    expect(gateway.values['app.new.key'], 'new');
  });

  test('keeps keys outside the configured prefix', () async {
    final gateway = FakeSecureStorageGateway()
      ..values.addAll(<String, String>{
        'app.access_token': 'owned',
        'com.other.app.token': 'foreign',
        'unrelated': 'keep',
      });
    final wipe = FirstRunWipe(
      gateway: gateway,
      storage: InMemoryStorage(),
      prefix: 'app.',
    );

    expect(await wipe.run(isIOS: true), isTrue);

    expect(gateway.values, <String, String>{
      'com.other.app.token': 'foreign',
      'unrelated': 'keep',
    });
  });

  test('does not write the marker when cleanup fails', () async {
    final gateway = FakeSecureStorageGateway()
      ..values['app.token'] = 'owned'
      ..failDeletes = true;
    final storage = InMemoryStorage();
    final wipe = FirstRunWipe(
      gateway: gateway,
      storage: storage,
      prefix: 'app.',
    );

    await expectLater(wipe.run(isIOS: true), throwsA(isA<StateError>()));

    expect(await storage.read('secure_storage.first_run_wiped'), isNull);
    expect(gateway.values['app.token'], 'owned');
  });
}
