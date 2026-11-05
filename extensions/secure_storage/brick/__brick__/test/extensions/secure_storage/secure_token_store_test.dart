import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_token_store.dart';

import 'test_support.dart';

void main() {
  test('saves, exposes, and clears tokens', () async {
    final storage = createTestSecureStorage();
    final store = SecureTokenStore(storage: storage);

    await store.save(accessToken: 'access', refreshToken: 'refresh');

    expect(await store.accessToken(), 'access');
    expect(await store.refreshToken(), 'refresh');

    await store.clear();
    expect(await store.accessToken(), isNull);
    expect(await store.refreshToken(), isNull);
  });
}
