import 'dart:async';
import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

import 'auth_request_policy.dart';
import 'auth_response_parser.dart';
import 'jwt_expiry.dart';
import 'rest_auth_config.dart';
import 'rest_auth_failure_mapper.dart';
import 'rest_token_store.dart';
import 'token_refresher.dart';

/// [AuthRepository] backed by REST endpoints and [SecureStorage].
final class RestAuth implements AuthRepository {
  RestAuth({
    required this.client,
    required this.store,
    this.config = RestAuthConfig.defaults,
    this.clock = const SystemClock(),
    AuthResponseParser? parser,
  }) : parser = parser ?? AuthResponseParser(clock: clock) {
    tokenProvider = TokenRefresher(
      store: store,
      clock: clock,
      leeway: config.refreshLeeway,
      exchange: _exchangeRefresh,
    );
  }

  final HttpClient client;
  final RestTokenStore store;
  final RestAuthConfig config;
  final Clock clock;
  final AuthResponseParser parser;
  late final TokenRefresher tokenProvider;
  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast(sync: true);
  AuthSession? _session;
  bool _initialized = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void> _commits = Future<void>.value();

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> get authStateChanges => _changes.stream;

  /// Restores a stored session, keeping it when the network is offline.
  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }
    _initialized = true;
    final generation = _generation;
    final stored = await store.read();
    if (stored == null || generation != _generation || _disposed) {
      return;
    }
    final cached = await store.readUser();
    if (generation != _generation || _disposed) return;
    if (cached != null) {
      final session = _sessionFrom(cached, stored);
      if (session != null) {
        _emit(session);
      }
    }
    try {
      await reloadSession();
    } on Failure {
      // Offline start keeps the cached session.
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final generation = _beginOperation();
    final response = await request(
      HttpMethod.post,
      config.loginPath,
      body: <String, Object?>{'email': email, 'password': password},
      authenticated: false,
      credential: true,
    );
    return _apply(response, generation);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final generation = _beginOperation();
    final response = await request(
      HttpMethod.post,
      config.registerPath,
      body: <String, Object?>{
        'email': email,
        'password': password,
        'displayName': ?displayName,
      },
      authenticated: false,
      credential: true,
    );
    return _apply(response, generation);
  }

  @override
  Future<void> signOut() async {
    // Local state is cleared before remote work so a slow or offline server
    // cannot keep the user signed in.
    final generation = _beginOperation();
    _emit(null);
    AuthTokens? tokens;
    Object? readError;
    StackTrace? readStack;
    try {
      tokens = await store.read();
    } on Object catch (error, stackTrace) {
      readError = error;
      readStack = stackTrace;
    }
    await _serializeCommit(() async {
      if (generation != _generation) {
        return;
      }
      await tokenProvider.clear();
    });
    if (generation != _generation || _disposed) return;
    if (readError != null) Error.throwWithStackTrace(readError, readStack!);
    if (config.logoutPath.isEmpty) {
      return;
    }
    try {
      await _sendLogout(tokens?.accessToken);
    } on Object {
      // Signing out must succeed offline.
    }
  }

  /// Clears local credentials without making another HTTP request.
  Future<void> clearSession() {
    final generation = _beginOperation();
    _emit(null);
    return _serializeCommit(() async {
      if (generation != _generation) {
        return;
      }
      await tokenProvider.clear();
    });
  }

  /// Reloads the current user from the me endpoint.
  Future<void> reloadSession() async {
    if (_disposed) return;
    final generation = _generation;
    final stored = await store.read();
    if (stored == null) {
      await _serializeCommit(() async {
        if (generation == _generation) {
          _emit(null);
        }
      });
      return;
    }
    final response = await request(HttpMethod.get, config.mePath);
    final user = _bodyMap(response.data);
    if (user == null) {
      throw const Failure(
        code: FailureCode.unexpected,
        message: 'The user profile response is not valid.',
        kind: FailureKind.authentication,
      );
    }
    final session = _sessionFrom(user, stored);
    if (session == null) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The user profile did not include an id.',
        kind: FailureKind.authentication,
      );
    }
    await _serializeCommit(() async {
      if (generation != _generation) {
        return;
      }
      final current = await store.read() ?? stored;
      if (generation != _generation || _disposed) return;
      await store.saveUser(user);
      if (generation != _generation || _disposed) return;
      _emit(_sessionFrom(user, current) ?? session);
    });
  }

  /// Refreshes the access token; returns null when no refresh token exists.
  Future<String?> refreshAccessToken({DateTime? deadline}) {
    return tokenProvider.accessToken(
      forceRefresh: true,
      deadline: deadline,
    );
  }

  /// Sends a request with JSON encoding and auth headers.
  Future<HttpResponse> request(
    HttpMethod method,
    String path, {
    Map<String, Object?>? body,
    bool authenticated = true,
    bool credential = false,
  }) async {
    if (path.isEmpty) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message: 'The REST endpoint is not configured.',
        kind: FailureKind.configuration,
      );
    }
    final endpoint = _backendEndpoint(path);
    final isLogout = path == config.logoutPath;
    final token = !authenticated
        ? null
        : isLogout
        ? (await store.read())?.accessToken
        : await tokenProvider.accessToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await client.send(
      HttpRequest(
        method: method,
        uri: endpoint,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    if (!response.isSuccessful) {
      throw credential
          ? mapCredentialResponse(response)
          : mapRestResponse(response);
    }
    return response;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _session = null;
    await _commits;
    await _changes.close();
  }

  Future<AuthSession> _apply(HttpResponse response, int generation) async {
    _ensureCurrent(generation);
    final body = _bodyMap(response.data);
    if (body == null) {
      throw const Failure(
        code: FailureCode.unexpected,
        message: 'The authentication response is not valid.',
        kind: FailureKind.authentication,
      );
    }
    final parsed = parser.parse(body);
    var user = parsed.user;
    final hasUserId =
        _string(user, const <String>[
          'id',
          'userId',
          'user_id',
          '_id',
          'uid',
          'sub',
        ]) !=
        null;
    var session = hasUserId ? _sessionFrom(user, parsed.tokens) : null;
    if (session == null) {
      final me = await _tryFetchMe(parsed.tokens.accessToken);
      if (generation != _generation) {
        throw _superseded();
      }
      if (me != null) {
        user = me;
        session = _sessionFrom(me, parsed.tokens);
      }
    }
    session ??= _sessionFrom(user, parsed.tokens);
    if (session == null) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The authentication response did not include a user id.',
        kind: FailureKind.authentication,
      );
    }
    final committed = session;
    final committedUser = user;
    return _serializeCommit(() async {
      _ensureCurrent(generation);
      try {
        await tokenProvider.clear();
        _ensureCurrent(generation);
        await store.save(parsed.tokens);
        _ensureCurrent(generation);
        await store.saveUser(committedUser);
        _ensureCurrent(generation);
        _emit(committed);
        return committed;
      } on Object catch (error, stackTrace) {
        // A partially written or superseded login must not restore next launch.
        // This commit owns the store until cleanup finishes; later commits wait.
        try {
          await tokenProvider.clear();
        } on Object catch (cleanupError) {
          throw Failure(
            code: FailureCode.storageWriteFailed,
            message:
                'The incomplete session could not be removed from storage.',
            kind: FailureKind.storage,
            cause: cleanupError,
            details: const {'localCleanupFailed': true},
          );
        }
        if (generation == _generation && !_disposed) _emit(null);
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  int _beginOperation() {
    if (_disposed) throw _superseded();
    return ++_generation;
  }

  void _ensureCurrent(int generation) {
    if (_disposed || generation != _generation) throw _superseded();
  }

  Future<Map<String, Object?>?> _tryFetchMe(String accessToken) async {
    if (config.mePath.isEmpty) {
      return null;
    }
    try {
      final response = await client.send(
        HttpRequest(
          method: HttpMethod.get,
          uri: _backendEndpoint(config.mePath),
          headers: <String, String>{
            'Accept': 'application/json',
            if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      if (!response.isSuccessful) {
        return null;
      }
      return _bodyMap(response.data);
    } on Failure {
      return null;
    }
  }

  Failure _superseded() => const Failure(
    code: FailureCode.authCancelled,
    message: 'The session changed while the request was in flight.',
    kind: FailureKind.authentication,
  );

  /// Runs session writes in order so late results cannot interleave.
  Future<T> _serializeCommit<T>(Future<T> Function() action) {
    final result = _commits.then((_) => action());
    _commits = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  AuthSession? _sessionFrom(Map<String, Object?> user, AuthTokens tokens) {
    final userId =
        _string(user, const <String>[
          'id',
          'userId',
          'user_id',
          '_id',
          'uid',
          'sub',
        ]) ??
        JwtExpiry.subjectOf(tokens.accessToken);
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final verified = _bool(user, const <String>[
      'emailVerified',
      'email_verified',
      'verified',
    ]);
    return AuthSession(
      userId: userId,
      expiresAt: tokens.expiresAt ?? JwtExpiry.expiryOf(tokens.accessToken),
      email: _string(user, const <String>['email']),
      displayName: _string(user, const <String>[
        'displayName',
        'display_name',
        'name',
      ]),
      metadata: <String, Object?>{'emailVerified': verified ?? false},
    );
  }

  Future<AuthTokens?> _exchangeRefresh(
    String refreshToken,
    DateTime? deadline,
  ) async {
    final generation = _generation;
    final response = await client.send(
      HttpRequest(
        method: HttpMethod.post,
        uri: _backendEndpoint(config.refreshPath),
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, Object?>{'refreshToken': refreshToken}),
        deadline: deadline,
      ),
    );
    if (!response.isSuccessful) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        final current = await store.read();
        // Only the session that issued this refresh may be cleared.
        if (generation == _generation &&
            current != null &&
            current.refreshToken == refreshToken) {
          await clearSession();
        }
      }
      throw mapRestResponse(response);
    }
    final body = _bodyMap(response.data);
    if (body == null) {
      throw const Failure(
        code: FailureCode.unexpected,
        message: 'The refresh response is not valid.',
        kind: FailureKind.authentication,
      );
    }
    final parsed = parser.parse(body);
    return parsed.tokens.refreshToken == null
        ? parsed.tokens.copyWith(refreshToken: refreshToken)
        : parsed.tokens;
  }

  /// Best-effort remote logout with the token captured before local clearing.
  Future<void> _sendLogout(String? accessToken) async {
    final response = await client.send(
      HttpRequest(
        method: HttpMethod.post,
        uri: _backendEndpoint(config.logoutPath),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(const <String, Object?>{}),
      ),
    );
    if (!response.isSuccessful) {
      throw mapRestResponse(response);
    }
  }

  Uri _backendEndpoint(String path) {
    final endpoint = config.endpoint(path);
    if (path.isEmpty || !AuthRequestPolicy(config).isBackend(endpoint)) {
      throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'REST auth endpoints must use the configured backend origin.',
        kind: FailureKind.configuration,
      );
    }
    return endpoint;
  }

  void _emit(AuthSession? session) {
    _session = session;
    if (!_changes.isClosed) {
      _changes.add(session);
    }
  }

  Map<String, Object?>? _bodyMap(Object? data) {
    if (data is Map) {
      return <String, Object?>{
        for (final entry in data.entries) '${entry.key}': entry.value,
      };
    }
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        return _bodyMap(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  String? _string(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  bool? _bool(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is bool) {
        return value;
      }
    }
    return null;
  }
}
