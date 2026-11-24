import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_failure_mapper.dart';

/// [CloudFunctions] on top of the Appwrite `Functions` service.
///
/// Every execution waits for completion, so the returned [FunctionExecution]
/// carries the function's own response status and body.
final class AppwriteFunctions implements CloudFunctions {
  AppwriteFunctions({required this.functions})
    : _mapper = const AppwriteFailureMapper();

  final Functions functions;
  final AppwriteFailureMapper _mapper;

  @override
  Future<FunctionExecution> invoke(
    String functionId, {
    Object? body,
    Map<String, String>? headers,
    String path = '/',
    String method = 'POST',
  }) async {
    if (functionId.trim().isEmpty) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message: 'A function id is required to invoke a cloud function.',
        kind: FailureKind.validation,
        details: <String, Object?>{'functionId': functionId},
      );
    }
    try {
      final execution = await functions.createExecution(
        functionId: functionId,
        body: body == null ? null : jsonEncode(body),
        headers: headers,
        path: path,
        method: _method(method),
      );
      return FunctionExecution(
        functionId: functionId,
        status: execution.status.value,
        statusCode: execution.responseStatusCode,
        body: execution.responseBody,
        responseHeaders: <String, String>{
          for (final header in execution.responseHeaders)
            if (header.name.isNotEmpty) header.name: header.value,
        },
        logs: execution.logs.isEmpty ? null : execution.logs,
        errors: execution.errors.isEmpty ? null : execution.errors,
        durationMs: execution.duration,
      );
    } on Object catch (error, stackTrace) {
      throw _mapper.map(
        error,
        scope: AppwriteFailureScope.functions,
        stackTrace: stackTrace,
      );
    }
  }

  ExecutionMethod _method(String method) {
    // The SDK codegen uses an unusual member casing; keep it contained here.
    final normalized = method.trim().toUpperCase();
    return switch (normalized) {
      'GET' => ExecutionMethod.gET,
      'POST' => ExecutionMethod.pOST,
      'PUT' => ExecutionMethod.pUT,
      'PATCH' => ExecutionMethod.pATCH,
      'DELETE' => ExecutionMethod.dELETE,
      'OPTIONS' => ExecutionMethod.oPTIONS,
      'HEAD' => ExecutionMethod.hEAD,
      _ => throw Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Cloud function method "$method" is not an HTTP method.',
        kind: FailureKind.validation,
        details: <String, Object?>{'method': method},
      ),
    };
  }
}
