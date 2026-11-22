import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_auth.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_token_store.dart';

import 'test_support.dart';

final class _FailingSecureStorage implements SecureStorage {
  _FailingSecureStorage(this.values);

  final Map<String, String> values;

  static const _failure = Failure(
    code: FailureCode.storageWriteFailed,
    message: 'Secure storage write failed',
    kind: FailureKind.storage,
  );

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => throw _failure;

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.unmodifiable(values);

  @override
  Future<void> clear() async => throw _failure;
}

final class _ControlledStorage implements SecureStorage {
  final inner = InMemorySecureStorage();
  Future<void> Function(String key)? beforeRead;
  Future<void> Function(String key)? beforeWrite;
  @override
  Future<String?> read(String key) async {
    final value = await inner.read(key);
    await beforeRead?.call(key);
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    await beforeWrite?.call(key);
    await inner.write(key, value);
  }

  @override
  Future<void> delete(String key) => inner.delete(key);
  @override
  Future<Map<String, String>> readAll() => inner.readAll();
  @override
  Future<void> clear() => inner.clear();
}

HttpResponse _loginResponse({
  required String userId,
  required String refreshToken,
}) {
  return HttpResponse(
    statusCode: 200,
    data: <String, Object?>{
      'access_token': makeJwt(subject: userId),
      'refresh_token': refreshToken,
      'user': <String, Object?>{'id': userId, 'email': '$userId@kiln.dev'},
    },
  );
}

void main() {
  test('logout wins over a cached-user read already in progress', () async {
    final storage = _ControlledStorage();
    final store = RestTokenStore(storage: storage);
    await store.save(
      AuthTokens(accessToken: makeJwt(), refreshToken: 'refresh'),
    );
    await store.saveUser({'id': 'user-old'});
    final entered = Completer<void>();
    final gate = Completer<void>();
    storage.beforeRead = (key) async {
      if (key.endsWith('.user')) {
        entered.complete();
        await gate.future;
      }
    };
    final auth = RestAuth(
      client: FakeHttpClient(onRequest: authServer),
      store: store,
      config: testConfig,
    );
    final emitted = <AuthSession?>[];
    final subscription = auth.authStateChanges.listen(emitted.add);
    final initializing = auth.initialize();
    await entered.future;
    await auth.signOut();
    gate.complete();
    await initializing;
    expect(auth.currentSession, isNull);
    expect(emitted.whereType<AuthSession>(), isEmpty);
    expect(storage.inner.snapshot, isEmpty);
    await subscription.cancel();
    await auth.dispose();
  });

  test(
    'logout during a token write cannot publish or persist that login',
    () async {
      final storage = _ControlledStorage();
      final auth = RestAuth(
        client: FakeHttpClient(onRequest: authServer),
        store: RestTokenStore(storage: storage),
        config: testConfig,
      );
      final gate = Completer<void>();
      final entered = Completer<void>();
      storage.beforeWrite = (key) async {
        if (key.endsWith('.access_token')) {
          entered.complete();
          await gate.future;
        }
      };
      final emitted = <AuthSession?>[];
      final subscription = auth.authStateChanges.listen(emitted.add);
      final login = auth.signIn(
        email: 'user@kiln.dev',
        password: 'password123',
      );
      final rejected = expectLater(
        login,
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            FailureCode.authCancelled,
          ),
        ),
      );
      await entered.future;
      final logout = auth.signOut();
      expect(auth.currentSession, isNull);
      gate.complete();
      await rejected;
      await logout;
      expect(emitted.whereType<AuthSession>(), isEmpty);
      expect(storage.inner.snapshot, isEmpty);
      await subscription.cancel();
      await auth.dispose();
    },
  );

  test(
    'a failed token read still clears local state and stored credentials',
    () async {
      final storage = _ControlledStorage();
      final auth = RestAuth(
        client: FakeHttpClient(onRequest: authServer),
        store: RestTokenStore(storage: storage),
        config: testConfig,
      );
      await auth.signIn(email: 'user@kiln.dev', password: 'password123');
      storage.beforeRead = (_) async => throw const Failure(
        code: FailureCode.storageReadFailed,
        message: 'Storage cannot be read.',
        kind: FailureKind.storage,
      );
      await expectLater(
        auth.signOut(),
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            FailureCode.storageReadFailed,
          ),
        ),
      );
      expect(auth.currentSession, isNull);
      expect(storage.inner.snapshot, isEmpty);
      await auth.dispose();
    },
  );

  test('signIn stores tokens, user, and emits the session', () async {
    final harness = AuthHarness();
    final emitted = <AuthSession?>[];
    final subscription = harness.auth.authStateChanges.listen(emitted.add);

    final session = await harness.auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(session.userId, 'user-1');
    expect(session.email, 'user@kiln.dev');
    expect(session.displayName, 'Tegar');
    expect(harness.auth.currentSession, session);
    expect(emitted.last, session);
    expect(harness.storage.snapshot['rest_auth.access_token'], isNotEmpty);
    expect(
      harness.storage.snapshot['rest_auth.refresh_token'],
      'refresh-token',
    );
    expect(harness.storage.snapshot['rest_auth.user'], contains('user-1'));

    await subscription.cancel();
  });

  test('signIn rejects invalid credentials without touching storage', () async {
    final harness = AuthHarness();

    await expectLater(
      harness.auth.signIn(email: 'user@kiln.dev', password: 'wrong'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authInvalidCredentials,
        ),
      ),
    );

    expect(harness.auth.currentSession, isNull);
    expect(harness.storage.snapshot, isEmpty);
  });

  test('signUp uses the register endpoint and display name', () async {
    final harness = AuthHarness();

    final session = await harness.auth.signUp(
      email: 'new@kiln.dev',
      password: 'password123',
      displayName: 'New User',
    );

    expect(session.userId, 'user-2');
    expect(session.displayName, 'New User');
    expect(harness.client.requests.single.uri.path, '/auth/register');
  });

  test('initialize restores the stored session', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final restored = AuthHarness(storage: harness.storage);

    await restored.auth.initialize();

    expect(restored.auth.currentSession, isNotNull);
    expect(restored.auth.currentSession?.userId, 'user-1');
    expect(restored.auth.currentSession?.displayName, 'Tegar P');
  });

  test('signOut clears the session and the store', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final emitted = <AuthSession?>[];
    final subscription = harness.auth.authStateChanges.listen(emitted.add);

    await harness.auth.signOut();

    expect(harness.auth.currentSession, isNull);
    expect(emitted, contains(null));
    expect(harness.storage.snapshot, isEmpty);

    await subscription.cancel();
  });

  test('signOut still clears tokens when the server fails', () async {
    final harness = AuthHarness();
    await harness.auth.signIn(email: 'user@kiln.dev', password: 'password123');
    harness.client.failure = const Failure(
      code: FailureCode.networkOffline,
      message: 'offline',
      kind: FailureKind.network,
    );

    await harness.auth.signOut();

    expect(harness.auth.currentSession, isNull);
    expect(harness.storage.snapshot, isEmpty);
  });

  test(
    'signOut clears local state before the remote request completes',
    () async {
      final logoutGate = Completer<void>();
      final client = FakeHttpClient(
        onRequest: (request) async {
          if (request.uri.path == '/auth/logout') {
            await logoutGate.future;
            return const HttpResponse(statusCode: 200);
          }
          return authServer(request);
        },
      );
      final harness = AuthHarness(client: client);
      await harness.auth.signIn(
        email: 'user@kiln.dev',
        password: 'password123',
      );

      final signOut = harness.auth.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(harness.auth.currentSession, isNull);
      expect(harness.storage.snapshot, isEmpty);
      final logoutRequest = client.requests.firstWhere(
        (request) => request.uri.path == '/auth/logout',
      );
      expect(logoutRequest.headers['Authorization'], startsWith('Bearer '));

      logoutGate.complete();
      await signOut;
    },
  );

  test('a delayed login cannot sign in after signOut', () async {
    final gate = Completer<void>();
    final client = FakeHttpClient(
      onRequest: (request) async {
        if (request.uri.path == '/auth/login') {
          await gate.future;
        }
        return authServer(request);
      },
    );
    final harness = AuthHarness(client: client);

    final login = harness.auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );
    await Future<void>.delayed(Duration.zero);
    await harness.auth.signOut();
    gate.complete();

    await expectLater(
      login,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authCancelled,
        ),
      ),
    );
    expect(harness.auth.currentSession, isNull);
    expect(harness.storage.snapshot, isEmpty);
  });

  test('a delayed login cannot replace a newer login', () async {
    final firstGate = Completer<void>();
    var logins = 0;
    final client = FakeHttpClient(
      onRequest: (request) async {
        if (request.uri.path == '/auth/login') {
          logins++;
          if (logins == 1) {
            await firstGate.future;
            return _loginResponse(userId: 'user-old', refreshToken: 'old');
          }
          return _loginResponse(userId: 'user-new', refreshToken: 'new');
        }
        return authServer(request);
      },
    );
    final harness = AuthHarness(client: client);

    final first = harness.auth.signIn(
      email: 'old@kiln.dev',
      password: 'password123',
    );
    await Future<void>.delayed(Duration.zero);
    final second = await harness.auth.signIn(
      email: 'new@kiln.dev',
      password: 'password123',
    );
    firstGate.complete();

    await expectLater(
      first,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authCancelled,
        ),
      ),
    );
    expect(second.userId, 'user-new');
    expect(harness.auth.currentSession?.userId, 'user-new');
    expect(harness.storage.snapshot['rest_auth.refresh_token'], 'new');
  });

  test('a delayed reload cannot overwrite a newer login', () async {
    final meGate = Completer<void>();
    var logins = 0;
    final client = FakeHttpClient(
      onRequest: (request) async {
        if (request.uri.path == '/auth/login') {
          logins++;
          return logins == 1
              ? _loginResponse(userId: 'user-old', refreshToken: 'old')
              : _loginResponse(userId: 'user-new', refreshToken: 'new');
        }
        if (request.uri.path == '/auth/me') {
          await meGate.future;
          return const HttpResponse(
            statusCode: 200,
            data: <String, Object?>{'id': 'user-old', 'email': 'old@kiln.dev'},
          );
        }
        return authServer(request);
      },
    );
    final harness = AuthHarness(client: client);
    await harness.auth.signIn(email: 'old@kiln.dev', password: 'password123');

    final reload = harness.auth.reloadSession();
    await Future<void>.delayed(Duration.zero);
    await harness.auth.signIn(email: 'new@kiln.dev', password: 'password123');
    meGate.complete();
    await reload;

    expect(harness.auth.currentSession?.userId, 'user-new');
    expect(harness.storage.snapshot['rest_auth.user'], contains('user-new'));
  });

  test('a storage failure during local sign-out is observable', () async {
    final storage = _FailingSecureStorage(<String, String>{
      'rest_auth.access_token': makeJwt(),
      'rest_auth.refresh_token': 'refresh-token',
    });
    final auth = RestAuth(
      client: FakeHttpClient(),
      store: RestTokenStore(storage: storage),
      config: testConfig,
    );

    await expectLater(
      auth.signOut(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.storageWriteFailed,
        ),
      ),
    );

    expect(auth.currentSession, isNull);
  });

  test('an old refresh rejection cannot clear a newer session', () async {
    final refreshGate = Completer<void>();
    var logins = 0;
    final client = FakeHttpClient(
      onRequest: (request) async {
        if (request.uri.path == '/auth/login') {
          logins++;
          return _loginResponse(
            userId: 'user-$logins',
            refreshToken: 'refresh-$logins',
          );
        }
        if (request.uri.path == '/auth/refresh') {
          await refreshGate.future;
          return const HttpResponse(statusCode: 401);
        }
        return authServer(request);
      },
    );
    final harness = AuthHarness(client: client);
    await harness.auth.signIn(email: 'one@kiln.dev', password: 'password123');

    final refresh = harness.auth.refreshAccessToken();
    await Future<void>.delayed(Duration.zero);
    await harness.auth.signIn(email: 'two@kiln.dev', password: 'password123');
    refreshGate.complete();

    await expectLater(
      refresh,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authSessionExpired,
        ),
      ),
    );
    expect(harness.auth.currentSession?.userId, 'user-2');
    expect(harness.storage.snapshot['rest_auth.refresh_token'], 'refresh-2');
  });
}
