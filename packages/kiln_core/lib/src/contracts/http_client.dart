import '../errors/failure.dart';
import '../errors/failure_codes.dart';

/// HTTP verbs supported by [HttpClient].
enum HttpMethod { get, post, put, patch, delete, head }

/// Cooperative cancellation for one request.
final class HttpCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
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
  });

  final HttpMethod method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;
  final Map<String, Object?>? queryParameters;
  final HttpCancelToken? cancelToken;

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
  }) {
    return HttpRequest(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      queryParameters: queryParameters ?? this.queryParameters,
      cancelToken: cancelToken ?? this.cancelToken,
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
