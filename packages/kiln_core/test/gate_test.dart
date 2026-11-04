import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _Permissions implements Permissions {
  _Permissions(this.result);

  PermissionStatus result;
  Failure? failure;

  @override
  Future<PermissionStatus> status(PermissionKind kind) => _respond();

  @override
  Future<PermissionStatus> request(PermissionKind kind) => _respond();

  @override
  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) => _respond();

  @override
  Future<bool> openSettings() async => true;

  Future<PermissionStatus> _respond() async {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    return result;
  }
}

final class _Storage implements Storage {
  final Map<String, String> values = <String, String>{};
  Failure? failure;

  @override
  Future<String?> read(String key) async {
    _throwIfFailed();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _throwIfFailed();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _throwIfFailed();
    values.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    _throwIfFailed();
    return values.containsKey(key);
  }

  @override
  Future<Set<String>> keys() async {
    _throwIfFailed();
    return values.keys.toSet();
  }

  @override
  Future<void> clear() async {
    _throwIfFailed();
    values.clear();
  }

  void _throwIfFailed() {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
  }
}

final class _SecureStorage implements SecureStorage {
  final Map<String, String> values = <String, String>{};
  Failure? failure;

  @override
  Future<String?> read(String key) async {
    _throwIfFailed();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _throwIfFailed();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _throwIfFailed();
    values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    _throwIfFailed();
    return Map<String, String>.unmodifiable(values);
  }

  @override
  Future<void> clear() async {
    _throwIfFailed();
    values.clear();
  }

  void _throwIfFailed() {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
  }
}

final class _HttpClient implements HttpClient {
  int sends = 0;
  HttpRequest? lastRequest;
  Failure? failure;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    sends++;
    lastRequest = request;
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    return const HttpResponse(statusCode: 200);
  }

  @override
  Future<HttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
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
    Map<String, String> headers = const <String, String>{},
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
    Map<String, String> headers = const <String, String>{},
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
    Map<String, String> headers = const <String, String>{},
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
    Map<String, String> headers = const <String, String>{},
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

final class _HttpCache implements HttpCache {
  final List<String> invalidated = <String>[];
  int clears = 0;

  @override
  Future<CacheEntry?> read(String key) async => null;

  @override
  Future<void> write(
    String key,
    HttpResponse response, {
    Duration? ttl,
    Set<String> tags = const <String>{},
  }) async {}

  @override
  Future<void> invalidate(String prefix, {String? tag}) async {
    invalidated.add(prefix);
  }

  @override
  Future<void> clear() async {
    clears++;
  }
}

final class _Location implements LocationProvider {
  bool serviceEnabled = true;
  GeoPosition? position;
  Failure? failure;

  @override
  Future<bool> isServiceEnabled() async {
    _throwIfFailed();
    return serviceEnabled;
  }

  @override
  Future<GeoPosition> current({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    _throwIfFailed();
    return position ??
        GeoPosition(
          latitude: 1,
          longitude: 2,
          timestamp: DateTime.utc(2026),
        );
  }

  @override
  Stream<GeoPosition> updates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 0,
  }) => const Stream<GeoPosition>.empty();

  void _throwIfFailed() {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
  }
}

void main() {
  group('Gate', () {
    late GetItRegistry registry;
    late _Permissions permissions;

    setUp(() {
      registry = GetItRegistry();
      permissions = _Permissions(PermissionStatus.granted);
      registry.registerSingleton<Permissions>(permissions);
    });

    test('use reads a registered service and has probes registration', () {
      final gate = Gate(registry);

      expect(gate.has<Permissions>(), isTrue);
      expect(gate.use<Permissions>(), same(permissions));
      expect(gate.has<AuthRepository>(), isFalse);
    });

    test('typed getters return the registered contracts', () {
      final gate = Gate(registry);

      expect(gate.permissions, same(permissions));
    });

    test('call returns Ok with the produced value', () async {
      final gate = Gate(registry);

      final result = await gate.call(
        () => permissions.ensure(PermissionKind.camera),
      );

      expect(result, isA<Ok<PermissionStatus>>());
      expect(result.valueOrNull, PermissionStatus.granted);
    });

    test('call returns Err with the thrown Failure', () async {
      permissions.failure = const Failure(
        code: FailureCode.permissionDenied,
        message: 'Denied',
        kind: FailureKind.permission,
      );
      final gate = Gate(registry);

      final result = await gate.call(
        () => permissions.ensure(PermissionKind.camera),
      );

      expect(result, isA<Err<PermissionStatus>>());
      expect(result.failureOrNull?.code, FailureCode.permissionDenied);
    });

    test('call merges info into the failure details', () async {
      permissions.failure = const Failure(
        code: FailureCode.permissionDenied,
        message: 'Denied',
        kind: FailureKind.permission,
      );
      final gate = Gate(registry);

      final result = await gate.call(
        () => permissions.ensure(PermissionKind.camera),
        info: const {'operation': 'camera'},
      );

      expect(result.failureOrNull?.details['operation'], 'camera');
      expect(result.failureOrNull?.details['statusCode'], isNull);
    });

    test('call wraps an unexpected error into Err', () async {
      final gate = Gate(registry);

      final result = await gate.call(
        () async => throw StateError('boom'),
        code: FailureCode.unexpected,
      );

      expect(result, isA<Err<PermissionStatus>>());
      expect(result.failureOrNull?.code, FailureCode.unexpected);
    });

    test('requestPermission returns a Result in one call', () async {
      final gate = Gate(registry);

      final result = await gate.requestPermission(PermissionKind.camera);

      expect(result, isA<Ok<PermissionStatus>>());
      expect(result.valueOrNull, PermissionStatus.granted);
    });

    test('requestPermission surfaces failures as Err', () async {
      permissions.failure = const Failure(
        code: FailureCode.permissionPermanentlyDenied,
        message: 'Permanent',
      );
      final gate = Gate(registry);

      final result = await gate.requestPermission(PermissionKind.camera);

      expect(
        result.failureOrNull?.code,
        FailureCode.permissionPermanentlyDenied,
      );
    });
  });

  group('Gate storage verbs', () {
    late GetItRegistry registry;
    late _Storage storage;

    setUp(() {
      registry = GetItRegistry();
      storage = _Storage();
      registry.registerSingleton<Storage>(storage);
    });

    test('readValue and hasValue read through the gate', () async {
      storage.values['theme'] = 'dark';
      final gate = Gate(registry);

      expect((await gate.readValue('theme')).valueOrNull, 'dark');
      expect((await gate.hasValue('theme')).valueOrNull, isTrue);
      expect((await gate.hasValue('missing')).valueOrNull, isFalse);
    });

    test('writeValue and deleteValue mutate through the gate', () async {
      final gate = Gate(registry);

      expect((await gate.writeValue('a', '1')).isOk, isTrue);
      expect(storage.values['a'], '1');

      expect((await gate.deleteValue('a')).isOk, isTrue);
      expect(storage.values.containsKey('a'), isFalse);
    });

    test('storageKeys and clearValues expose the remaining contract', () async {
      storage.values
        ..['a'] = '1'
        ..['b'] = '2';
      final gate = Gate(registry);

      expect((await gate.storageKeys()).valueOrNull, <String>{'a', 'b'});

      await gate.clearValues();
      expect(storage.values, isEmpty);
    });

    test('storage verbs surface failures as Err', () async {
      storage.failure = const Failure(
        code: FailureCode.storageReadFailed,
        message: 'read',
        kind: FailureKind.storage,
      );
      final gate = Gate(registry);

      expect(
        (await gate.readValue('x')).failureOrNull?.code,
        FailureCode.storageReadFailed,
      );
    });
  });

  group('Gate secure storage verbs', () {
    late GetItRegistry registry;
    late _SecureStorage secureStorage;

    setUp(() {
      registry = GetItRegistry();
      secureStorage = _SecureStorage();
      registry.registerSingleton<SecureStorage>(secureStorage);
    });

    test('readSecure and readAllSecure read through the gate', () async {
      secureStorage.values['token'] = 't';
      final gate = Gate(registry);

      expect((await gate.readSecure('token')).valueOrNull, 't');
      expect((await gate.readAllSecure()).valueOrNull, <String, String>{
        'token': 't',
      });
    });

    test('writeSecure and deleteSecure mutate through the gate', () async {
      final gate = Gate(registry);

      expect((await gate.writeSecure('a', '1')).isOk, isTrue);
      expect(secureStorage.values['a'], '1');

      expect((await gate.deleteSecure('a')).isOk, isTrue);
      expect(secureStorage.values.containsKey('a'), isFalse);
    });

    test('clearSecure clears the store', () async {
      secureStorage.values['a'] = '1';
      final gate = Gate(registry);

      await gate.clearSecure();
      expect(secureStorage.values, isEmpty);
    });

    test('secure storage verbs surface failures as Err', () async {
      secureStorage.failure = const Failure(
        code: FailureCode.secureStorageUnavailable,
        message: 'unavailable',
        kind: FailureKind.storage,
      );
      final gate = Gate(registry);

      expect(
        (await gate.readSecure('x')).failureOrNull?.code,
        FailureCode.secureStorageUnavailable,
      );
    });
  });

  group('Gate http verbs', () {
    late GetItRegistry registry;
    late _HttpClient http;

    setUp(() {
      registry = GetItRegistry();
      http = _HttpClient();
      registry.registerSingleton<HttpClient>(http);
    });

    test('httpSend and httpGet return the response', () async {
      final gate = Gate(registry);

      final sent = await gate.httpSend(
        HttpRequest(method: HttpMethod.get, uri: Uri.parse('https://x.dev')),
      );
      expect(sent.valueOrNull?.statusCode, 200);

      final got = await gate.httpGet(Uri.parse('https://x.dev'));
      expect(got.valueOrNull?.statusCode, 200);
      expect(http.sends, 2);
    });

    test('httpPost forwards the body', () async {
      final gate = Gate(registry);

      final result = await gate.httpPost(
        Uri.parse('https://x.dev'),
        body: <String, Object?>{'a': 1},
      );

      expect(result.valueOrNull?.statusCode, 200);
      expect(http.lastRequest?.body, <String, Object?>{'a': 1});
    });

    test('http verbs surface failures as Err', () async {
      http.failure = const Failure(
        code: FailureCode.networkTimeout,
        message: 'timeout',
        kind: FailureKind.network,
      );
      final gate = Gate(registry);

      final result = await gate.httpGet(Uri.parse('https://x.dev'));

      expect(result.failureOrNull?.code, FailureCode.networkTimeout);
    });
  });

  group('Gate http cache verbs', () {
    late GetItRegistry registry;
    late _HttpCache cache;

    setUp(() {
      registry = GetItRegistry();
      cache = _HttpCache();
      registry.registerSingleton<HttpCache>(cache);
    });

    test('cache getter reads the registered cache', () {
      expect(Gate(registry).cache, same(cache));
    });

    test('invalidateCache and clearCache delegate', () async {
      final gate = Gate(registry);

      expect(
        (await gate.invalidateCache('/users', tag: 'users')).isOk,
        isTrue,
      );
      expect(cache.invalidated, <String>['/users']);

      expect((await gate.clearCache()).isOk, isTrue);
      expect(cache.clears, 1);
    });
  });

  group('Gate location verbs', () {
    late GetItRegistry registry;
    late _Location location;

    setUp(() {
      registry = GetItRegistry();
      location = _Location();
      registry.registerSingleton<LocationProvider>(location);
    });

    test('currentLocation returns a position', () async {
      final gate = Gate(registry);

      final result = await gate.currentLocation();

      expect(result.valueOrNull?.latitude, 1);
    });

    test('locationServiceEnabled reports the service state', () async {
      final gate = Gate(registry);

      expect((await gate.locationServiceEnabled()).valueOrNull, isTrue);

      location.serviceEnabled = false;
      expect((await gate.locationServiceEnabled()).valueOrNull, isFalse);
    });

    test('location verbs surface failures as Err', () async {
      location.failure = const Failure(
        code: FailureCode.unavailable,
        message: 'no fix',
        kind: FailureKind.unavailable,
      );
      final gate = Gate(registry);

      expect(
        (await gate.currentLocation()).failureOrNull?.code,
        FailureCode.unavailable,
      );
    });
  });
}
