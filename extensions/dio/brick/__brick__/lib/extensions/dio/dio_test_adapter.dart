import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef DioTestHandler = Future<ResponseBody> Function(RequestOptions options);

/// [HttpClientAdapter] that answers from a callback instead of a network.
final class DioTestAdapter implements HttpClientAdapter {
  DioTestAdapter(this.handler);

  final DioTestHandler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}
