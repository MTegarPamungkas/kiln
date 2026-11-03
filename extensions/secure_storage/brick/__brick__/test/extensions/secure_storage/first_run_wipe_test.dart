import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/secure_storage/first_run_wipe.dart';

import 'test_support.dart';

void main() {
  test('wipes Keychain leftovers only on the first iOS run', () async {
    final gateway = FakeSecureStorageGateway()
      ..values['old.key'] = 'old';
    final storage = InMemoryStorage();
    final wipe = FirstRunWipe(gateway: gateway, storage: storage);

    expect(await wipe.run(isIOS: false), isFalse);
    expect(gateway.values, isNotEmpty);

    expect(await wipe.run(isIOS: true), isTrue);
    expect(gateway.values, isEmpty);
    expect(await storage.read('secure_storage.first_run_wiped'), 'true');

    gateway.values['new.key'] = 'new';
    expect(await wipe.run(isIOS: true), isFalse);
    expect(gateway.values['new.key'], 'new');
  });
}
