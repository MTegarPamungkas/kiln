import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kiln_core/kiln_core.dart';

import 'dio_config.dart';
import 'dio_failure_mapper.dart';

/// [HttpClient] implementation backed by dio and [HttpPipeline].
class DioClient implements HttpClient {
  DioClient({
    Dio? dio,
    DioConfig config = DioConfig.defaults,
    HttpPipeline? pipeline,
    this.clock = const SystemClock(),
  }) : _ownsDio = dio == null,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.baseUrl,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               headers: config.defaultHeaders,
             ),
           ),
       _config = config,
       _pipeline = pipeline ?? HttpPipeline();

  final bool _ownsDio;
  final Dio _dio;
  final DioConfig _config;
  final HttpPipeline _pipeline;

  /// Clock used to evaluate [HttpRequest.deadline] deterministically in tests.
  final Clock clock;

  /// Transport access for helpers in this extension (multipart and download).
  Dio get dio => _dio;

  /// Closes the transport only when this client created it; an injected [Dio]
  /// stays owned by the caller.
  void close({bool force = false}) {
    if (_ownsDio) {
      _dio.close(force: force);
    }
  }

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    try {
      // Policy middleware must see the same origin and credentials as the wire.
      // Otherwise default Authorization headers can bypass cache isolation.
      final headers = <String, String>{
        for (final entry in _dio.options.headers.entries)
          entry.key: '${entry.value}',
      };
      for (final entry in request.headers.entries) {
        headers.removeWhere(
          (key, _) => key.toLowerCase() == entry.key.toLowerCase(),
        );
        headers[entry.key] = entry.value;
      }
      final resolved = request.copyWith(
        uri: _resolveUri(request.uri),
        headers: headers,
      );
      final effective = _withApiKey(resolved, resolved.resolvedUri);
      return await _pipeline.execute(effective, _send);
    } on Failure {
      rethrow;
    } on DioException catch (error) {
      throw mapDioException(error);
    } catch (error, stackTrace) {
      throw Failure.from(
        error,
        code: FailureCode.networkUnknown,
        kind: FailureKind.network,
        stackTrace: stackTrace,
      );
    }
  }

  Future<HttpResponse> _send(HttpRequest request) async {
    request.cancelToken?.throwIfCancelled();
    final startedAt = clock.now().toUtc();
    request.throwIfDeadlineExceeded(startedAt);
    final remaining = request.remainingUntil(startedAt);
    final target = _resolveUri(request.resolvedUri);
    final authorized = _withApiKey(request, target);
    final uri = _resolveUri(authorized.resolvedUri);
    final dioCancel = CancelToken();
    final removeCancelListener = authorized.cancelToken?.onCancel(
      dioCancel.cancel,
    );
    var deadlineExpired = false;
    final deadlineTimer = remaining == null
        ? null
        : Timer(remaining, () {
            deadlineExpired = true;
            dioCancel.cancel();
          });
    try {
      // Every received HTTP status is a response. Only transport failures are
      // mapped to Failure, so auth, retry, cache, and log middleware can apply
      // their own status policies to the same exchange.
      final response = await _dio.fetch<Object?>(
        Options(
          method: authorized.method.name.toUpperCase(),
          headers: authorized.headers,
          validateStatus: (_) => true,
          sendTimeout: remaining == null
              ? null
              : (remaining < _config.connectTimeout
                    ? remaining
                    : _config.connectTimeout),
          receiveTimeout: remaining == null
              ? null
              : (remaining < _config.receiveTimeout
                    ? remaining
                    : _config.receiveTimeout),
        ).compose(
          _dio.options,
          uri.toString(),
          data: authorized.body,
          cancelToken: dioCancel,
        ),
      );
      authorized.cancelToken?.throwIfCancelled();

      return HttpResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        headers: <String, List<String>>{
          for (final entry in response.headers.map.entries)
            entry.key: entry.value,
        },
        requestUri: uri,
        duration: clock.now().toUtc().difference(startedAt),
      );
    } on DioException catch (error) {
      if (deadlineExpired ||
          authorized.isDeadlineExceeded(clock.now().toUtc())) {
        throw const Failure(
          code: FailureCode.networkDeadlineExceeded,
          message: 'Request deadline exceeded',
          kind: FailureKind.network,
        );
      }
      // Middleware must see the shared Failure so retry policies can react.
      throw mapDioException(error);
    } finally {
      deadlineTimer?.cancel();
      removeCancelListener?.call();
    }
  }

  Uri _resolveUri(Uri uri) {
    if (uri.hasScheme) {
      return uri;
    }
    final baseUrl = _dio.options.baseUrl;
    if (baseUrl.isEmpty) {
      return uri;
    }
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final relative = uri.toString().replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base$relative');
  }

  HttpRequest _withApiKey(HttpRequest request, Uri target) {
    final key = _config.apiKey;
    if (!_config.hasApiKey || !_isBackend(target)) {
      return request;
    }
    if (_config.apiKeyHeader.isNotEmpty) {
      return request.copyWith(
        headers: <String, String>{
          ...request.headers,
          _config.apiKeyHeader: '${_config.apiKeyPrefix}$key',
        },
      );
    }
    if (_config.apiKeyQueryParameter.isNotEmpty) {
      return request.copyWith(
        queryParameters: <String, Object?>{
          ...?request.queryParameters,
          _config.apiKeyQueryParameter: key,
        },
      );
    }
    return request;
  }

  bool _isBackend(Uri uri) {
    final base = Uri.tryParse(_dio.options.baseUrl);
    return base != null &&
        base.host.isNotEmpty &&
        (base.isScheme('http') || base.isScheme('https')) &&
        uri.scheme == base.scheme &&
        uri.host == base.host &&
        uri.port == base.port;
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
