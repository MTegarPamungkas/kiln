import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/storage/namespaced_storage.dart';

import 'test_support.dart';

void main() {
  test('separates keys by namespace and clears only its own', () async {
    final inner = createTestStorage();
    final users = NamespacedStorage(inner: inner, namespace: 'users');
    final cache = NamespacedStorage(inner: inner, namespace: 'cache');

    await users.write('token', 'u');
    await cache.write('token', 'c');

    expect(await users.read('token'), 'u');
    expect(await cache.read('token'), 'c');
    expect(await users.keys(), {'token'});

    await users.clear();
    expect(await users.read('token'), isNull);
    expect(await cache.read('token'), 'c');
  });
}
