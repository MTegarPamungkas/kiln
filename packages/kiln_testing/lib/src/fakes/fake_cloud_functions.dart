import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// [CloudFunctions] that echoes the request body back as a completed
/// execution, with configurable unknown-function failures.
final class FakeCloudFunctions implements CloudFunctions {
  FakeCloudFunctions({
    this.knownFunctions = const <String>{'hello-kiln'},
    this.failure,
  });

  final Set<String> knownFunctions;
  Failure? failure;
  final List<String> calls = <String>[];

  @override
  Future<FunctionExecution> invoke(
    String functionId, {
    Object? body,
    Map<String, String>? headers,
    String path = '/',
    String method = 'POST',
  }) async {
    calls.add('invoke:$functionId:$method');
    if (!knownFunctions.contains(functionId)) {
      throw Failure(
        code: FailureCode.functionsNotFound,
        message: 'Function "$functionId" is not deployed.',
        kind: FailureKind.unknown,
        details: <String, Object?>{'functionId': functionId},
      );
    }
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    return FunctionExecution(
      functionId: functionId,
      status: 'completed',
      statusCode: 200,
      body: jsonEncode(<String, Object?>{
        'echo': body,
        'path': path,
        'method': method,
        'headers': headers ?? const <String, String>{},
      }),
      logs: 'fake execution log',
      durationMs: 1.0,
    );
  }
}
