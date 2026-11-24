import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart' as sdk;
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_core/kiln_core.dart' hide HttpClient;
import 'package:kiln_testing/kiln_testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_auth.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_session_bridge.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_session_store.dart';

final class _Jar {
  List<Cookie> cookies = [];
  bool deleted = false;

  Future<void> saveFromResponse(Uri uri, List<Cookie> values) async {
    cookies = values;
  }

  Future<void> delete(Uri uri) async {
    cookies = [];
    deleted = true;
  }
}

final class _Client extends Fake implements sdk.Client {
  _Client({
    this.endPoint = 'https://api.example.com/v1',
    String project = 'project-a',
  }) : config = {'project': project};
  @override
  final String endPoint;
  @override
  Map<String, String> config;
  final cookieJar = _Jar();
  @override
  sdk.Client setSession(String value) {
    config['session'] = value;
    return this;
  }

  @override
  sdk.Client setCookie(String value) {
    config['cookie'] = value;
    return this;
  }

  @override
  sdk.Client setJWT(String value) {
    config['jWT'] = value;
    return this;
  }

  @override
  sdk.Client setBearer(String value) {
    config['bearer'] = value;
    return this;
  }
}

final class _Account extends sdk.Account {
  _Account(super.client);
  Future<models.User> Function()? getHandler;
  Future<void> Function()? deleteHandler;
  int getCalls = 0;
  int jwtCalls = 0;

  @override
  Future<models.User> get() async {
    getCalls++;
    final handler = getHandler;
    if (handler != null) return handler();
    if ((client.config['session'] ?? '').isEmpty) {
      throw sdk.AppwriteException('Unauthorized', 401);
    }
    return models.User.fromMap({
      r'$id': 'user-a',
      'email': 'user@example.com',
      'prefs': <String, dynamic>{},
    });
  }

  @override
  Future<void> deleteSessions({bool? current}) async {
    await deleteHandler?.call();
  }

  @override
  Future<models.Jwt> createJWT({int? duration}) async {
    jwtCalls++;
    return models.Jwt(jwt: 'jwt-user-a');
  }
}

final class _Store implements AppwriteSessionStore {
  final values = <String, String>{};
  bool failDeletes = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('Storage unavailable');
    values.remove(key);
  }
}

final class _DeferredAccount extends Fake implements AppwriteAccount {
  Future<AppwriteAuthResult> Function()? login;
  Future<AppwriteAccountUser?> Function()? user;
  Future<String?> Function()? token;
  int tokenCalls = 0;
  @override
  Future<AppwriteAccountUser?> currentUser() => user!();
  @override
  Future<String?> createJwt() {
    tokenCalls++;
    return token!();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  }) => login!();
}

http.Response _loginResponse([String? cookie]) => http.Response(
  jsonEncode({
    r'$id': 'session-a',
    'userId': 'user-a',
    'expire': '2030-01-01T00:00:00Z',
  }),
  201,
  headers: {
    'set-cookie':
        cookie ?? 'a_session_project-a=session%2Fsecret; Path=/; HttpOnly',
  },
);

({
  Gate gate,
  AppwriteAuth auth,
  AppwriteSessionBridge bridge,
  SessionController controller,
  AppwriteTokenProvider tokens,
})
_wire(SdkAppwriteAccount adapter) {
  final controller = SessionController();
  final tokens = AppwriteTokenProvider(account: adapter);
  final bridge = AppwriteSessionBridge(
    controller: controller,
    tokenProvider: tokens,
  );
  final auth = AppwriteAuth(account: adapter, bridge: bridge);
  final registry = GetItRegistry()..registerSingleton<AuthRepository>(auth);
  addTearDown(bridge.dispose);
  addTearDown(controller.dispose);
  return (
    gate: Gate(registry),
    auth: auth,
    bridge: bridge,
    controller: controller,
    tokens: tokens,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'restoring a scoped cookie preserves literal percent sequences',
    () async {
      final client = _Client();
      final key = SdkAppwriteAccount.sessionCookieKeyFor(
        client.endPoint,
        'project-a',
      );
      SharedPreferences.setMockInitialValues({key: 'opaque%2Fsession'});
      final adapter = SdkAppwriteAccount(
        account: _Account(client),
        client: client,
      );
      expect(await adapter.currentUser(), isNotNull);
      expect(client.config['session'], 'opaque%2Fsession');
    },
  );

  test(
    'an older restore cannot cancel a new login that has not completed yet',
    () async {
      final old = Completer<AppwriteAccountUser?>();
      final next = Completer<AppwriteAuthResult>();
      final account = _DeferredAccount()..user = () => old.future;
      account.login = () => next.future;
      final bridge = AppwriteSessionBridge();
      addTearDown(bridge.dispose);
      final auth = AppwriteAuth(account: account, bridge: bridge);
      final restore = auth.restoreSession();
      final login = auth.signIn(
        email: 'new@example.com',
        password: 'test-password',
      );
      old.complete(
        const AppwriteAccountUser(id: 'old', email: 'old@example.com'),
      );
      await restore;
      next.complete(
        const AppwriteAuthResult(
          user: AppwriteAccountUser(id: 'new', email: 'new@example.com'),
          session: AppwriteAccountSession(id: 'new-session', userId: 'new'),
        ),
      );
      expect((await login).userId, 'new');
      expect(auth.currentSession?.userId, 'new');
    },
  );

  test(
    'secure storage retains logout markers and removes old plaintext copies',
    () async {
      final storage = InMemorySecureStorage();
      final store = SecureAppwriteSessionStore(storage);
      final key = SdkAppwriteAccount.sessionCookieKeyFor(
        'https://api.example.com/v1',
        'project-a',
      );
      const marker =
          'kiln.appwrite.signedOut.https://api.example.com/v1.project-a';
      SharedPreferences.setMockInitialValues({
        marker: true,
        key: 'old-cookie',
        SdkAppwriteAccount.sessionCookieKey: 'legacy-cookie',
      });
      expect(await store.read(marker), 'true');
      expect(
        await store.read(key),
        isNull,
        reason: 'old plaintext cookies are not imported silently',
      );
      await store.write(key, 'secure-cookie');
      expect(await storage.read(key), 'secure-cookie');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(key), isFalse);
      expect(prefs.containsKey(SdkAppwriteAccount.sessionCookieKey), isFalse);
      await store.delete(marker);
      expect(await store.read(marker), isNull);
      await store.delete(key);
      expect(await storage.read(key), isNull);
    },
  );

  test('JWT cache expiry uses the injected clock', () async {
    final clock = FakeClock(DateTime.utc(2026));
    final account = _DeferredAccount()..token = () async => 'token';
    final tokens = AppwriteTokenProvider(account: account, clock: clock);
    expect(await tokens.accessToken(), 'token');
    clock.advance(const Duration(minutes: 13));
    expect(await tokens.accessToken(), 'token');
    expect(account.tokenCalls, 1);
    clock.advance(const Duration(minutes: 1));
    expect(await tokens.accessToken(), 'token');
    expect(account.tokenCalls, 2);
  });

  test(
    'Gate login persists a scoped session, restores it, and logs out offline',
    () async {
      final client = _Client();
      final account = _Account(client);
      final transport = MockClient((request) async {
        expect(request.url.path, '/v1/account/sessions/email');
        expect(request.headers['X-Appwrite-Project'], 'project-a');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['password'], 'test-password');
        return _loginResponse();
      });
      addTearDown(transport.close);
      final wired = _wire(
        SdkAppwriteAccount(
          account: account,
          client: client,
          loginClient: transport,
        ),
      );
      expect(
        (await wired.gate.signIn(
          email: 'user@example.com',
          password: 'test-password',
        )).isOk,
        isTrue,
      );
      expect(wired.controller.isAuthenticated, isTrue);
      expect(client.cookieJar.cookies.single.value, 'session/secret');
      final prefs = await SharedPreferences.getInstance();
      final key = SdkAppwriteAccount.sessionCookieKeyFor(
        client.endPoint,
        'project-a',
      );
      expect(prefs.getString(key), 'session/secret');
      expect(prefs.containsKey(SdkAppwriteAccount.sessionCookieKey), isFalse);
      expect(await wired.tokens.accessToken(), 'jwt-user-a');

      final restartedClient = _Client();
      final restartedAccount = _Account(restartedClient);
      final restarted = _wire(
        SdkAppwriteAccount(account: restartedAccount, client: restartedClient),
      );
      await restarted.auth.restoreSession();
      expect(restarted.auth.currentSession?.userId, 'user-a');
      expect(await restarted.tokens.accessToken(), 'jwt-user-a');
      restartedAccount.deleteHandler = () async =>
          throw TimeoutException('Offline');
      expect((await restarted.gate.signOut()).isOk, isTrue);
      expect(restarted.controller.status, SessionStatus.unauthenticated);
      expect(await restarted.tokens.accessToken(), isNull);
      expect(prefs.containsKey(key), isFalse);
      expect(restartedClient.cookieJar.deleted, isTrue);
      for (final name in ['session', 'cookie', 'jWT', 'bearer']) {
        expect(restartedClient.config[name] ?? '', isEmpty);
      }
      final signedOutClient = _Client();
      final signedOutAccount = _Account(signedOutClient);
      expect(
        await SdkAppwriteAccount(
          account: signedOutAccount,
          client: signedOutClient,
        ).currentUser(),
        isNull,
      );
      expect(signedOutAccount.getCalls, 0);
    },
  );

  test('cookies never cross endpoint/project boundaries and legacy cookies are ignored', () async {
    final key = SdkAppwriteAccount.sessionCookieKeyFor(
      'https://api.example.com/v1',
      'project-a',
    );
    SharedPreferences.setMockInitialValues({
      key: 'private-session-a',
      SdkAppwriteAccount.sessionCookieKey: 'unscoped-private-session',
    });
    for (final client in [
      _Client(project: 'project-b'),
      _Client(endPoint: 'https://other.example.com/v1'),
    ]) {
      final account = _Account(client);
      expect(
        await SdkAppwriteAccount(
          account: account,
          client: client,
        ).currentUser(),
        isNull,
      );
      expect(client.config['session'], isNot('private-session-a'));
      expect(client.cookieJar.cookies, isEmpty);
    }
    expect(
      (await SharedPreferences.getInstance()).getString(key),
      'private-session-a',
    );
  });

  test(
    'combined Set-Cookie headers retain the correct decoded session cookie',
    () async {
      final client = _Client();
      final transport = MockClient(
        (_) async => _loginResponse(
          'other=value; Expires=Wed, 21 Oct 2030 07:28:00 GMT, a_session_project-a=correct%2Fcookie; Path=/',
        ),
      );
      addTearDown(transport.close);
      await SdkAppwriteAccount(
        account: _Account(client),
        client: client,
        loginClient: transport,
      ).signIn(email: 'user@example.com', password: 'test-password');
      expect(client.config['session'], 'correct/cookie');
    },
  );

  test(
    'a login timeout returns a typed failure and leaves no persisted session',
    () async {
      final response = Completer<http.Response>();
      final transport = MockClient((_) => response.future);
      addTearDown(transport.close);
      final client = _Client();
      final wired = _wire(
        SdkAppwriteAccount(
          account: _Account(client),
          client: client,
          loginClient: transport,
          requestTimeout: const Duration(milliseconds: 20),
        ),
      );
      final result = await wired.gate.signIn(
        email: 'user@example.com',
        password: 'test-password',
      );
      expect(result.failureOrNull?.code, FailureCode.networkTimeout);
      response.complete(_loginResponse());
      await Future<void>.delayed(Duration.zero);
      expect(wired.auth.currentSession, isNull);
      expect(client.config['session'] ?? '', isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString(
          SdkAppwriteAccount.sessionCookieKeyFor(client.endPoint, 'project-a'),
        ),
        isNull,
      );
    },
  );

  test('logout supersedes an in-flight HTTP login without resurrecting the session', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final transport = MockClient((_) {
      started.complete();
      return response.future;
    });
    addTearDown(transport.close);
    final client = _Client();
    final wired = _wire(
      SdkAppwriteAccount(
        account: _Account(client),
        client: client,
        loginClient: transport,
      ),
    );
    final login = wired.gate.signIn(
      email: 'user@example.com',
      password: 'test-password',
    );
    await started.future;
    final logout = wired.gate.signOut();
    expect(wired.controller.status, SessionStatus.unauthenticated);
    response.complete(_loginResponse());
    expect((await login).failureOrNull?.code, FailureCode.authCancelled);
    expect((await logout).isOk, isTrue);
    expect(wired.auth.currentSession, isNull);
    expect(client.config['session'] ?? '', isEmpty);
  });

  test('a signed-out restore does not introduce unused credential headers', () async {
    SharedPreferences.setMockInitialValues({});
    final client = _Client();
    final wired = _wire(SdkAppwriteAccount(account: _Account(client), client: client));
    await wired.auth.restoreSession();
    for (final name in ['session', 'cookie', 'jWT', 'bearer']) {
      expect(client.config.containsKey(name), isFalse,
        reason: 'Clearing absent credentials must not add CORS request headers.');
    }
  });

  test(
    'a 401 during restore clears transport credentials and persisted cookies',
    () async {
      final client = _Client()
        ..setJWT('old-jwt')
        ..setBearer('old-bearer');
      final key = SdkAppwriteAccount.sessionCookieKeyFor(
        client.endPoint,
        'project-a',
      );
      SharedPreferences.setMockInitialValues({key: 'expired-session'});
      final account = _Account(client)
        ..getHandler = () async =>
            throw sdk.AppwriteException('Expired session', 401);
      final wired = _wire(SdkAppwriteAccount(account: account, client: client));
      await wired.auth.restoreSession();
      expect(wired.auth.currentSession, isNull);
      expect((await SharedPreferences.getInstance()).containsKey(key), isFalse);
      for (final name in ['session', 'cookie', 'jWT', 'bearer']) {
        expect(client.config[name] ?? '', isEmpty);
      }
    },
  );

  test(
    'failed local cleanup is reported even though application state is cleared',
    () async {
      final client = _Client()..setSession('retained-session');
      final store = _Store();
      final key = SdkAppwriteAccount.sessionCookieKeyFor(
        client.endPoint,
        'project-a',
      );
      store.values[key] = 'retained-session';
      store.failDeletes = true;
      final wired = _wire(
        SdkAppwriteAccount(
          account: _Account(client),
          client: client,
          sessionStore: store,
        ),
      );
      wired.bridge.establish(
        user: const AppwriteAccountUser(
          id: 'user-a',
          email: 'user@example.com',
        ),
      );
      final result = await wired.gate.signOut();
      expect(result.failureOrNull?.details['localCleanupFailed'], isTrue);
      expect(wired.auth.currentSession, isNull);
      expect(store.values[key], 'retained-session');
    },
  );

  test('late restore cannot revive a logged-out or disposed bridge', () async {
    final response = Completer<AppwriteAccountUser?>();
    final account = _DeferredAccount()..user = () => response.future;
    final bridge = AppwriteSessionBridge();
    final auth = AppwriteAuth(account: account, bridge: bridge);
    final restore = auth.restoreSession();
    await auth.signOut();
    await bridge.dispose();
    response.complete(
      const AppwriteAccountUser(id: 'old-user', email: 'old@example.com'),
    );
    await restore;
    expect(auth.currentSession, isNull);
  });

  test('an old restore failure cannot clear a newer session', () async {
    final response = Completer<AppwriteAccountUser?>();
    final account = _DeferredAccount()..user = () => response.future;
    final bridge = AppwriteSessionBridge();
    addTearDown(bridge.dispose);
    final auth = AppwriteAuth(account: account, bridge: bridge);
    final restore = auth.restoreSession();
    bridge.establish(
      user: const AppwriteAccountUser(id: 'new-user', email: 'new@example.com'),
    );
    response.completeError(sdk.AppwriteException('Expired session', 401));
    await restore;
    expect(auth.currentSession?.userId, 'new-user');
  });

  test(
    'JWT requests are shared and a cleared request cannot repopulate the cache',
    () async {
      final old = Completer<String?>();
      final fresh = Completer<String?>();
      final account = _DeferredAccount()..token = () => old.future;
      final tokens = AppwriteTokenProvider(account: account);
      final first = tokens.accessToken();
      final shared = tokens.accessToken();
      expect(account.tokenCalls, 1);
      await tokens.clear();
      account.token = () => fresh.future;
      final next = tokens.accessToken();
      old.complete('old-token');
      expect(await first, isNull);
      expect(await shared, isNull);
      fresh.complete('new-token');
      expect(await next, 'new-token');
      expect(await tokens.accessToken(), 'new-token');
      expect(account.tokenCalls, 2);
    },
  );
}
