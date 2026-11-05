import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/secure_storage/namespaced_secure_storage.dart';

import 'test_support.dart';

void main() {
  test('separates secrets by namespace', () async {
    final inner = createTestSecureStorage();
    final auth = NamespacedSecureStorage(inner: inner, namespace: 'auth');
    final cache = NamespacedSecureStorage(inner: inner, namespace: 'cache');

    await auth.write('token', 'a');
    await cache.write('token', 'c');

    expect(await auth.read('token'), 'a');
    expect(await cache.read('token'), 'c');
    expect(await auth.readAll(), {'token': 'a'});

    await auth.clear();
    expect(await auth.read('token'), isNull);
    expect(await cache.read('token'), 'c');
  });
}
