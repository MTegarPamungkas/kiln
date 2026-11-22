import '../errors/failure.dart';
import '../errors/failure_codes.dart';

/// HTTP verbs supported by [HttpClient].
enum HttpMethod { get, post, put, patch, delete, head }

/// Cooperative cancellation for one request.
final class HttpCancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  /// Notifies [listener] when cancelled. Returns a function that removes it.
  ///
  /// An already cancelled token notifies immediately, so transports that only
  /// learn about the token later still abort.
  void Function() onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const Failure(
        code: FailureCode.cancelled,
        message: 'Request was cancelled',
        kind: FailureKind.cancelled,
      );
    }
  }
}

/// Backend-neutral HTTP request.
final class HttpRequest {
  const HttpRequest({
    required this.method,
    required this.uri,
    this.headers = const <String, String>{},
    this.body,
    this.queryParameters,
    this.cancelToken,
    this.deadline,
  });

  final HttpMethod method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;
  final Map<String, Object?>? queryParameters;
  final HttpCancelToken? cancelToken;

  /// Absolute wall-clock deadline for the whole request, or null when unbounded.
  ///
  /// Middleware and adapters stop starting new work once the deadline passes
  /// and report [FailureCode.networkDeadlineExceeded]. A cache hit may still be
  /// returned because it needs no work. This does not abort an in-flight plugin
  /// or transport call; cancellation remains cooperative through
  /// [cancelToken]. A layer that builds a follow-up request (for example an auth
  /// refresh) should copy this value so the caller's budget stays shared.
  final DateTime? deadline;

  /// Time left before [deadline], null when there is no deadline.
  Duration? remainingUntil(DateTime now) {
    final target = deadline;
    if (target == null) {
      return null;
    }
    final remaining = target.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isDeadlineExceeded(DateTime now) {
    final target = deadline;
    return target != null && !now.isBefore(target);
  }

  /// Throws the typed deadline failure once [deadline] has passed.
  void throwIfDeadlineExceeded(DateTime now) {
    if (isDeadlineExceeded(now)) {
      throw const Failure(
        code: FailureCode.networkDeadlineExceeded,
        message: 'Request deadline exceeded',
        kind: FailureKind.network,
      );
    }
  }

  Uri get resolvedUri {
    final query = queryParameters;
    if (query == null || query.isEmpty) {
      return uri;
    }
    final merged = <String, dynamic>{
      ...uri.queryParametersAll,
      for (final entry in query.entries)
        entry.key: entry.value is Iterable
            ? (entry.value! as Iterable).map((value) => '$value').toList()
            : '${entry.value}',
    };
    return uri.replace(queryParameters: merged);
  }

  HttpRequest copyWith({
    HttpMethod? method,
    Uri? uri,
    Map<String, String>? headers,
    Object? body,
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
    DateTime? deadline,
  }) {
    return HttpRequest(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      queryParameters: queryParameters ?? this.queryParameters,
      cancelToken: cancelToken ?? this.cancelToken,
      deadline: deadline ?? this.deadline,
    );
  }
}

/// Backend-neutral HTTP response.
final class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    this.data,
    this.headers = const <String, List<String>>{},
    this.requestUri,
    this.duration,
    this.fromCache = false,
  });

  final int statusCode;
  final Object? data;
  final Map<String, List<String>> headers;
  final Uri? requestUri;
  final Duration? duration;
  final bool fromCache;

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  String? header(String name) {
    final lower = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lower && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }

  HttpResponse copyWith({
    int? statusCode,
    Object? data,
    Map<String, List<String>>? headers,
    Uri? requestUri,
    Duration? duration,
    bool? fromCache,
  }) {
    return HttpResponse(
      statusCode: statusCode ?? this.statusCode,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      requestUri: requestUri ?? this.requestUri,
      duration: duration ?? this.duration,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

typedef HttpHandler = Future<HttpResponse> Function(HttpRequest request);

/// One layer of the HTTP pipeline. Middleware never imports a transport.
abstract interface class HttpMiddleware {
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next);
}

/// Sends requests. Implementations translate failures into [Failure].
abstract interface class HttpClient {
  Future<HttpResponse> send(HttpRequest request);

  Future<HttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  });

  Future<HttpResponse> post(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  });

  Future<HttpResponse> put(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  });

  Future<HttpResponse> patch(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  });

  Future<HttpResponse> delete(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  });
}

/// Ordered middleware executed around a transport.
final class HttpPipeline {
  HttpPipeline([List<HttpMiddleware> middleware = const <HttpMiddleware>[]]) {
    for (final item in middleware) {
      use(item);
    }
  }

  final List<HttpMiddleware> _middleware = <HttpMiddleware>[];
  final List<int> _priorities = <int>[];

  List<HttpMiddleware> get middleware =>
      List<HttpMiddleware>.unmodifiable(_sortedMiddleware());

  void use(HttpMiddleware middleware, {int priority = 0}) {
    _middleware.add(middleware);
    _priorities.add(priority);
  }

  void useAll(Iterable<HttpMiddleware> middleware, {int priority = 0}) {
    for (final item in middleware) {
      use(item, priority: priority);
    }
  }

  Future<HttpResponse> execute(HttpRequest request, HttpHandler terminal) {
    final ordered = _sortedMiddleware();
    var handler = terminal;
    for (final middleware in ordered.reversed) {
      final next = handler;
      handler = (request) => middleware.handle(request, next);
    }
    return handler(request);
  }

  List<HttpMiddleware> _sortedMiddleware() {
    final indices = List<int>.generate(_middleware.length, (index) => index);
    indices.sort((left, right) {
      final byPriority = _priorities[left].compareTo(_priorities[right]);
      return byPriority != 0 ? byPriority : left.compareTo(right);
    });
    return <HttpMiddleware>[for (final index in indices) _middleware[index]];
  }
}

/// One cached response and the metadata required to reuse it.
final class CacheEntry {
  const CacheEntry({
    required this.response,
    required this.storedAt,
    this.ttl,
    this.tags = const <String>{},
  });

  final HttpResponse response;
  final DateTime storedAt;
  final Duration? ttl;
  final Set<String> tags;

  bool isFresh(DateTime now) {
    final timeToLive = ttl;
    return timeToLive == null || now.isBefore(storedAt.add(timeToLive));
  }
}

/// A response cache used by HTTP middleware.
abstract interface class HttpCache {
  Future<CacheEntry?> read(String key);

  Future<void> write(
    String key,
    HttpResponse response, {
    Duration? ttl,
    Set<String> tags = const <String>{},
  });

  Future<void> invalidate(String prefix, {String? tag});

  Future<void> clear();
}
