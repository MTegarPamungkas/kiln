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
  }) : _dio =
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

  final Dio _dio;
  final DioConfig _config;
  final HttpPipeline _pipeline;

  /// Transport access for helpers in this extension (multipart and download).
  Dio get dio => _dio;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    try {
      return await _pipeline.execute(request, _send);
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
    final startedAt = DateTime.now();
    final target = _resolveUri(request.resolvedUri);
    final authorized = _withApiKey(request, target);
    final uri = _resolveUri(authorized.resolvedUri);
    try {
      final response = await _dio.fetch<Object?>(
        RequestOptions(
          path: uri.toString(),
          method: authorized.method.name.toUpperCase(),
          headers: <String, dynamic>{
            ..._dio.options.headers,
            ...authorized.headers,
          },
          data: authorized.body,
        ),
      );

      return HttpResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        headers: <String, List<String>>{
          for (final entry in response.headers.map.entries)
            entry.key: entry.value,
        },
        requestUri: uri,
        duration: DateTime.now().difference(startedAt),
      );
    } on DioException catch (error) {
      // Middleware must see the shared Failure so retry policies can react.
      throw mapDioException(error);
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
