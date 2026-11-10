import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/rest_auth/auth_middleware.dart';
import 'package:full_stack/extensions/rest_auth/auth_request_policy.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth.dart';
import 'package:full_stack/extensions/rest_auth/rest_token_store.dart';
import 'package:full_stack/extensions/rest_auth/unauthorized_handler.dart';

import 'test_support.dart';

/// Drives the real pipeline from the transport side, like DioClient does.
final class _PipelineClient implements HttpClient {
  _PipelineClient(this.pipeline);

  final HttpPipeline pipeline;
  final List<HttpRequest> requests = <HttpRequest>[];

  @override
  Future<HttpResponse> send(HttpRequest request) {
    requests.add(request);
    return pipeline.execute(request, realtimeTerminal);
  }

  @override
  Future<HttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.get,
      uri: uri,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> post(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.post,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> put(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.put,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> patch(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.patch,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<HttpResponse> delete(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => send(
    HttpRequest(
      method: HttpMethod.delete,
      uri: uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );
}

final List<HttpRequest> _terminalRequests = <HttpRequest>[];

Future<HttpResponse> realtimeTerminal(HttpRequest request) async {
  _terminalRequests.add(request);
  final path = request.uri.path;
  String? authorization;
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == 'authorization') authorization = entry.value;
  }
  if (path == '/auth/refresh') {
    return HttpResponse(
      statusCode: 200,
      data: <String, Object?>{
        'accessToken': 'h.p.fresh',
        'refreshToken': 'refresh-rotated',
      },
    );
  }
  if (path == '/auth/login') {
    final body = request.body is String ? request.body! as String : '';
    if (!body.contains('password123')) {
      return const HttpResponse(
        statusCode: 401,
        data: <String, Object?>{'message': 'Invalid credentials'},
      );
    }
    return HttpResponse(
      statusCode: 200,
      data: <String, Object?>{
        'access_token': 'h.p.login',
        'refresh_token': 'refresh-login',
        'user': <String, Object?>{'id': 'user-1', 'email': 'user@kiln.dev'},
      },
    );
  }
  if (path == '/auth/me') {
    return authorization == 'Bearer h.p.fresh'
        ? const HttpResponse(
            statusCode: 200,
            data: <String, Object?>{'id': 'user-1'},
          )
        : const HttpResponse(statusCode: 401);
  }
  if (path == '/auth/logout') {
    return const HttpResponse(statusCode: 200);
  }
  return const HttpResponse(statusCode: 404);
}

({RestAuth auth, HttpPipeline pipeline, _PipelineClient client}) _build(
  RestTokenStore store,
) {
  final pipeline = HttpPipeline();
  final client = _PipelineClient(pipeline);
  final auth = RestAuth(client: client, store: store, config: testConfig);
  const policy = AuthRequestPolicy(testConfig);
  pipeline
    ..use(AuthMiddleware(auth.tokenProvider, policy: policy), priority: 10)
    ..use(
      UnauthorizedHandler(
        policy: policy,
        refresh: auth.refreshAccessToken,
        signOut: auth.clearSession,
      ),
      priority: 11,
    );
  return (auth: auth, pipeline: pipeline, client: client);
}

void main() {
  setUp(_terminalRequests.clear);

  test(
    'an expired token refreshes through the same pipeline without stalling',
    () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 10));
      final store = RestTokenStore(storage: InMemorySecureStorage());
      await store.save(
        AuthTokens(
          accessToken: 'h.p.expired',
          refreshToken: 'refresh-old',
          expiresAt: clock.now().subtract(const Duration(hours: 1)),
        ),
      );
      final built = _build(store);

      final response = await built.auth.client
          .send(
            HttpRequest(
              method: HttpMethod.get,
              uri: Uri.parse('https://api.kiln.dev/auth/me'),
            ),
          )
          .timeout(const Duration(seconds: 2));

      expect(response.statusCode, 200);
      expect(_terminalRequests.map((request) => request.uri.path), [
        '/auth/refresh',
        '/auth/me',
      ]);
      expect((await store.read())?.accessToken, 'h.p.fresh');
    },
  );

  test('the shared client never sends the token to a foreign origin', () async {
    final store = RestTokenStore(storage: InMemorySecureStorage());
    await store.save(const AuthTokens(accessToken: 'h.p.current'));
    final built = _build(store);

    await built.auth.client.send(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://cdn.third-party.test/file'),
      ),
    );

    expect(
      _terminalRequests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('a failed login completes with a typed failure and keeps the pipeline usable', () async {
    final store = RestTokenStore(storage: InMemorySecureStorage());
    final built = _build(store);

    await expectLater(
      built.auth.signIn(email: 'user@kiln.dev', password: 'wrong'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authInvalidCredentials,
        ),
      ),
    );
    expect(_terminalRequests.map((request) => request.uri.path), [
      '/auth/login',
    ]);

    final again = await built.auth.client.send(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/auth/me'),
      ),
    );
    expect(again.statusCode, 401);
  });
}
