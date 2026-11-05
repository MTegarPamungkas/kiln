import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/rest_auth/rest_token_store.dart';

void main() {
  test('saves and clears tokens and the cached user', () async {
    final storage = InMemorySecureStorage();
    final store = RestTokenStore(storage: storage);
    final expiresAt = DateTime.utc(2026, 11, 2, 9);

    await store.save(
      AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: expiresAt,
      ),
    );
    await store.saveUser(const <String, Object?>{'id': 'user-1'});

    final stored = await store.read();
    expect(stored?.accessToken, 'access');
    expect(stored?.refreshToken, 'refresh');
    expect(stored?.expiresAt, expiresAt);
    expect(await store.refreshToken(), 'refresh');
    expect((await store.readUser())?['id'], 'user-1');
    expect(storage.snapshot.keys, contains('rest_auth.access_token'));

    await store.clear();
    expect(await store.read(), isNull);
    expect(await store.readUser(), isNull);
  });

  test('returns null when no access token exists', () async {
    final store = RestTokenStore(storage: InMemorySecureStorage());

    expect(await store.read(), isNull);
  });

  test('ignores malformed cached users', () async {
    final storage = InMemorySecureStorage(<String, String>{
      'rest_auth.user': 'not json',
    });
    final store = RestTokenStore(storage: storage);

    expect(await store.readUser(), isNull);
  });
}
