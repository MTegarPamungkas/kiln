import 'package:kiln_core/kiln_core.dart';

/// Records requests and returns programmed responses without touching a socket.
final class FakeHttpClient implements HttpClient {
  FakeHttpClient({
    this.onRequest,
    this.defaultResponse = const HttpResponse(statusCode: 200),
    this.failure,
    this.throwOnError = false,
  });

  final List<HttpRequest> requests = <HttpRequest>[];
  Future<HttpResponse> Function(HttpRequest request)? onRequest;
  HttpResponse defaultResponse;
  Failure? failure;

  /// Throws a [Failure] for non-2xx responses, matching dio's default
  /// behavior. Disabled by default so response-shape tests can inspect them.
  final bool throwOnError;

  int get callCount => requests.length;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    request.cancelToken?.throwIfCancelled();
    requests.add(request);
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    final handler = onRequest;
    final response = handler == null ? defaultResponse : await handler(request);
    if (throwOnError && !response.isSuccessful) {
      throw _failureFor(response.statusCode);
    }
    return response;
  }

  Failure _failureFor(int statusCode) {
    if (statusCode == 404) {
      return Failure(
        code: FailureCode.unavailable,
        message: 'Fake response returned 404',
        kind: FailureKind.unavailable,
        details: <String, Object?>{'statusCode': statusCode},
      );
    }
    if (statusCode == 429 || statusCode >= 500) {
      return Failure(
        code: FailureCode.networkServer,
        message: 'Fake response returned $statusCode',
        kind: FailureKind.network,
        details: <String, Object?>{'statusCode': statusCode},
        isRetryable: true,
      );
    }
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: 'Fake response returned $statusCode',
      kind: FailureKind.validation,
      details: <String, Object?>{'statusCode': statusCode},
    );
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
