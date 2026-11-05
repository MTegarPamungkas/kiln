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
  }) : _dio = dio ??
           Dio(
             BaseOptions(
               baseUrl: config.baseUrl,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               headers: config.defaultHeaders,
             ),
           ),
       _pipeline = pipeline ?? HttpPipeline();

  final Dio _dio;
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
    final response = await _dio.fetch<Object?>(
      RequestOptions(
        path: request.resolvedUri.toString(),
        method: request.method.name.toUpperCase(),
        headers: <String, dynamic>{
          ..._dio.options.headers,
          ...request.headers,
        },
        data: request.body,
      ),
    );

    return HttpResponse(
      statusCode: response.statusCode ?? 0,
      data: response.data,
      headers: <String, List<String>>{
        for (final entry in response.headers.map.entries)
          entry.key: entry.value,
      },
      requestUri: request.resolvedUri,
      duration: DateTime.now().difference(startedAt),
    );
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
