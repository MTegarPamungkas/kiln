// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

import 'neon_storage_config.dart';
import 'neon_token_provider.dart';

/// Storage operations, injectable independently of the HTTP transport.
abstract interface class NeonStorageGateway {
  Future<void> upload(
    String key,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata,
    ProgressCallback? onProgress,
  });
  Future<List<int>> download(String key, {ProgressCallback? onProgress});
  Future<Uri> createSignedUrl(String key, Duration expiresIn);
  Future<void> delete(String key);
}

enum _Operation {
  upload('PUT', FailureCode.fileUploadFailed),
  download('GET', FailureCode.fileDownloadFailed),
  delete('DELETE', FailureCode.fileDeleteFailed);

  const _Operation(this.method, this.failureCode);
  final String method;
  final FailureCode failureCode;
}

/// Obtains scoped URLs from an application-owned presigning backend.
/// The user JWT is sent only to that endpoint, never to the object host.
/// Injected clients and token providers are borrowed; their owner closes them.
final class PresignedNeonStorageGateway implements NeonStorageGateway {
  PresignedNeonStorageGateway({
    required NeonStorageConfig config,
    required NeonTokenProvider tokenProvider,
    http.Client? client,
  }) : _config = config,
       _tokenProvider = tokenProvider,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final NeonStorageConfig _config;
  final NeonTokenProvider _tokenProvider;
  final http.Client _client;
  final bool _ownsClient;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }

  @override
  Future<void> upload(
    String key,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata = const <String, String>{},
    ProgressCallback? onProgress,
  }) => _guard(_Operation.upload, () async {
    final signed = await _presign(
      _Operation.upload, key, contentType: contentType, metadata: metadata,
    );
    await _objectRequest(_Operation.upload, signed, bytes: bytes);
    onProgress?.call(1);
  });

  @override
  Future<List<int>> download(String key, {ProgressCallback? onProgress}) =>
      _guard(_Operation.download, () async {
        final signed = await _presign(_Operation.download, key);
        final response = await _objectRequest(_Operation.download, signed);
        onProgress?.call(1);
        return response.bodyBytes;
      });

  @override
  Future<Uri> createSignedUrl(String key, Duration expiresIn) =>
      _guard(_Operation.download, () async {
        final signed = await _presign(_Operation.download, key, expiresIn: expiresIn);
        // A URL-only API cannot carry required headers to its consumer.
        if (signed.headers.isNotEmpty) {
          throw _invalidResponse(_Operation.download);
        }
        return signed.url;
      });

  @override
  Future<void> delete(String key) => _guard(_Operation.delete, () async {
    final signed = await _presign(_Operation.delete, key);
    await _objectRequest(_Operation.delete, signed);
  });

  Future<({Uri url, Map<String, String> headers})> _presign(
    _Operation operation,
    String key, {
    String? contentType,
    Map<String, String>? metadata,
    Duration? expiresIn,
  }) async {
    final problem = _config.validate();
    if (problem != null) throw problem;
    final lifetime = expiresIn ?? _config.signedUrlLifetime;
    if (!NeonStorageConfig.isValidLifetime(lifetime) ||
        key.trim().isEmpty ||
        utf8.encode(key).length > 1024 ||
        key.startsWith('/') ||
        key.split('/').any((part) => part == '..' || part == '.') ||
        RegExp(r'[\x00-\x1f\x7f\\]').hasMatch(key) ||
        (contentType != null && !_safeValue(contentType)) ||
        (metadata != null && metadata.entries.any(
          (entry) => !_headerName.hasMatch(entry.key) || !_safeValue(entry.value),
        ))) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Invalid storage key, metadata, or lifetime (whole seconds, 1–900).',
        kind: FailureKind.validation,
      );
    }
    final token = await _tokenProvider.token();
    if (token == null || token.trim().isEmpty || !_safeValue(token)) {
      throw const Failure(
        code: FailureCode.authUnauthorized,
        message: 'Sign in before accessing storage.',
        kind: FailureKind.authentication,
      );
    }
    final request = http.Request('POST', Uri.parse(_config.signingUrl))
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      })
      ..body = jsonEncode({
        'operation': operation.name,
        'bucket': _config.bucket,
        'key': key,
        'contentType': ?contentType,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        'expiresIn': lifetime.inSeconds,
      });
    final streamed = await _client.send(request);
    // Bound an untrusted signing response before decoding it.
    final body = <int>[];
    await for (final chunk in streamed.stream) {
      if (body.length + chunk.length > 65536) throw _invalidResponse(operation);
      body.addAll(chunk);
    }
    _ensureOk(streamed.statusCode, operation);
    final Object? decoded = jsonDecode(utf8.decode(body));
    if (decoded is! Map<String, dynamic> || decoded['url'] is! String ||
        (decoded.containsKey('method') && decoded['method'] != operation.method)) {
      throw _invalidResponse(operation);
    }
    final rawUrl = decoded['url'] as String;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.isScheme('https') || !uri.hasAuthority ||
        uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment ||
        rawUrl.trim() != rawUrl || RegExp(r'[\x00-\x20\x7f\\]').hasMatch(rawUrl) ||
        rawUrl.contains(token) || rawUrl.contains(Uri.encodeComponent(token))) {
      throw _invalidResponse(operation);
    }
    final headers = <String, String>{};
    if (decoded.containsKey('headers')) {
      final value = decoded['headers'];
      if (value is! Map<String, dynamic> || value.length > 64) {
        throw _invalidResponse(operation);
      }
      for (final entry in value.entries) {
        final name = entry.key.toLowerCase();
        final header = entry.value;
        if (!_headerName.hasMatch(name) || _forbiddenHeaders.contains(name) ||
            name.startsWith('proxy-') || name.startsWith('sec-') ||
            name.startsWith('x-http-method') || headers.containsKey(name) ||
            header is! String || !_safeValue(header) || header.contains(token)) {
          throw _invalidResponse(operation);
        }
        headers[name] = header;
      }
    }
    return (url: uri, headers: headers);
  }

  static final _headerName = RegExp(r"^[!#$%&'*+.^_`|~0-9a-zA-Z-]+$");
  static const _forbiddenHeaders = {
    'authorization', 'cookie', 'cookie2', 'host', 'content-length',
    'connection', 'transfer-encoding', 'trailer', 'te', 'upgrade',
    'expect', 'origin', 'referer',
  };
  static bool _safeValue(String value) =>
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value);

  Future<http.Response> _objectRequest(
    _Operation operation,
    ({Uri url, Map<String, String> headers}) signed, {
    List<int>? bytes,
  }) async {
    final request = http.Request(operation.method, signed.url)
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers.addAll(signed.headers);
    if (bytes != null) request.bodyBytes = bytes;
    final response = await http.Response.fromStream(await _client.send(request));
    _ensureOk(response.statusCode, operation);
    return response;
  }

  void _ensureOk(int status, _Operation operation) {
    if (status >= 200 && status < 300) return;
    throw Failure(
      code: switch (status) {
        401 => FailureCode.authUnauthorized,
        403 => FailureCode.permissionDenied,
        404 => FailureCode.fileNotFound,
        _ => operation.failureCode,
      },
      message: 'The storage ${operation.name} request failed with status $status.',
      kind: FailureKind.storage,
      details: {'statusCode': status},
    );
  }

  Failure _invalidResponse(_Operation operation) => Failure(
    code: operation.failureCode,
    message: 'The storage signing backend returned an invalid response.',
    kind: FailureKind.storage,
  );

  Future<T> _guard<T>(_Operation operation, Future<T> Function() action) async {
    try {
      if (_closed) throw StateError('Storage gateway is closed.');
      return await action();
    } on Failure {
      rethrow;
    } on Object {
      // Do not expose bearer tokens, signed URLs, or raw server bodies in errors.
      throw Failure(
        code: operation.failureCode,
        message: 'The storage ${operation.name} request could not be completed.',
        kind: FailureKind.storage,
      );
    }
  }
}
