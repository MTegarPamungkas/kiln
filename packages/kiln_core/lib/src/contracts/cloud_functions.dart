import 'dart:convert';

/// Outcome of one cloud function execution.
///
/// The execution itself is the fact: a function that returns a non-2xx
/// [statusCode] or [status] `failed` still produces a completed invocation,
/// because the platform answered. Transport, permission, and lookup problems
/// throw [Failure] instead.
final class FunctionExecution {
  const FunctionExecution({
    required this.functionId,
    required this.status,
    required this.statusCode,
    required this.body,
    this.responseHeaders = const <String, String>{},
    this.logs,
    this.errors,
    this.durationMs,
  });

  /// The function that was executed.
  final String functionId;

  /// Backend-neutral lifecycle state, e.g. `completed` or `failed`.
  final String status;

  /// HTTP-style status code the function responded with; `-1` when the
  /// backend cannot express one.
  final int statusCode;

  /// Raw response body as returned by the function.
  final String body;

  /// Response headers the function returned, when the backend reports them.
  final Map<String, String> responseHeaders;

  /// Backend-side logs captured during execution, when available.
  final String? logs;

  /// Backend-side errors captured during execution, when available.
  final String? errors;

  /// Wall-clock execution time in milliseconds, when the backend reports it.
  final double? durationMs;

  /// Convenience for JSON-style bodies: parses [body] when it is valid JSON,
  /// else returns null.
  Object? get bodyJson {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}

/// Executes cloud functions deployed on the application's backend.
///
/// Appwrite maps this to `Functions.createExecution`; Supabase maps it to
/// Edge Function invocation; Firebase maps it to callable functions.
abstract interface class CloudFunctions {
  /// Executes [functionId] and waits for completion.
  ///
  /// [body] is sent as the JSON request body; [headers] travel with the
  /// request; [path] and [method] address the function's route when the
  /// backend supports per-path invocation.
  Future<FunctionExecution> invoke(
    String functionId, {
    Object? body,
    Map<String, String>? headers,
    String path = '/',
    String method = 'POST',
  });
}
