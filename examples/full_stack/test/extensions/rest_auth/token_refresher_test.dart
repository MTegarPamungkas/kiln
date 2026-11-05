import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/rest_auth/rest_token_store.dart';
import 'package:full_stack/extensions/rest_auth/token_refresher.dart';

import 'test_support.dart';

void main() {
  test('returns a valid token without refreshing', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 2, 9));
    final storage = InMemorySecureStorage();
    final store = RestTokenStore(storage: storage);
    await store.save(
      AuthTokens(
        accessToken: makeJwt(expiresAt: DateTime.utc(2026, 11, 2, 10)),
        refreshToken: 'refresh',
      ),
    );
    var calls = 0;
    final refresher = TokenRefresher(
      store: store,
      clock: clock,
      exchange: (_) async {
        calls++;
        return null;
      },
    );

    expect(await refresher.accessToken(), isNotEmpty);
    expect(calls, 0);
  });

  test('shares one refresh between concurrent callers', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 2, 9));
    final storage = InMemorySecureStorage();
    final store = RestTokenStore(storage: storage);
    await store.save(
      AuthTokens(
        accessToken: makeJwt(expiresAt: DateTime.utc(2026, 11, 2, 8)),
        refreshToken: 'refresh',
      ),
    );
    var calls = 0;
    final refresher = TokenRefresher(
      store: store,
      clock: clock,
      exchange: (refreshToken) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return AuthTokens(
          accessToken: makeJwt(expiresAt: DateTime.utc(2026, 11, 2, 10)),
          refreshToken: '$refreshToken-rotated',
        );
      },
    );

    final results = await Future.wait(<Future<String?>>[
      refresher.accessToken(forceRefresh: true),
      refresher.accessToken(forceRefresh: true),
    ]);

    expect(calls, 1);
    expect(results.first, results.last);
    expect(await store.refreshToken(), 'refresh-rotated');
  });

  test('returns null when there is no refresh token', () async {
    final store = RestTokenStore(storage: InMemorySecureStorage());
    var calls = 0;
    final refresher = TokenRefresher(
      store: store,
      exchange: (_) async {
        calls++;
        return null;
      },
    );

    expect(await refresher.accessToken(forceRefresh: true), isNull);
    expect(calls, 0);
  });

  test('clear removes stored tokens', () async {
    final store = RestTokenStore(storage: InMemorySecureStorage());
    await store.save(const AuthTokens(accessToken: 'a', refreshToken: 'b'));
    final refresher = TokenRefresher(store: store, exchange: (_) async => null);

    await refresher.clear();

    expect(await store.read(), isNull);
  });
}
