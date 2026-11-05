import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

import 'remote_config_gateway.dart';

/// [RemoteConfigGateway] backed by `package:http`.
///
/// Reads an absolute URL that returns a JSON object and decodes it into the
/// flat value map the client expects. Tests replace this with a fake gateway so
/// no socket is opened.
final class HttpRemoteConfigGateway implements RemoteConfigGateway {
  HttpRemoteConfigGateway({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Map<String, Object?>> load(String url, {Duration? timeout}) async {
    final uri = Uri.parse(url);
    http.Response response;
    try {
      final request = _client.get(uri, headers: const <String, String>{
        'Accept': 'application/json',
      });
      response = timeout == null ? await request : await request.timeout(timeout);
    } on TimeoutException {
      throw Failure(
        code: FailureCode.networkTimeout,
        message: 'Remote config request timed out.',
        kind: FailureKind.network,
        details: <String, Object?>{'url': url},
      );
    } on Object catch (error) {
      throw Failure(
        code: FailureCode.unavailable,
        message: 'Remote config request failed: $error',
        kind: FailureKind.network,
        details: <String, Object?>{'url': url, 'error': '$error'},
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Failure(
        code: FailureCode.unavailable,
        message: 'Remote config returned HTTP ${response.statusCode}.',
        kind: FailureKind.unavailable,
        details: <String, Object?>{
          'url': url,
          'statusCode': response.statusCode,
        },
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Remote config body was not valid JSON: ${error.message}',
        kind: FailureKind.validation,
        details: <String, Object?>{'url': url},
      );
    }
    if (decoded is! Map) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Remote config JSON must be an object of key/value pairs.',
        kind: FailureKind.validation,
      );
    }
    return decoded.map(
      (Object? key, Object? value) => MapEntry('$key', value),
    );
  }

  @override
  Future<void> close() async => _client.close();
}
