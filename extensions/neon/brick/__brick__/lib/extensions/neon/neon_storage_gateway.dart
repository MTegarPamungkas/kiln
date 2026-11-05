// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiln_core/kiln_core.dart';

import 'neon_s3_signer.dart';
import 'neon_storage_config.dart';

/// Neon Object Storage operations used by [NeonFileStorage], wrapped so the S3
/// transport can be faked in tests.
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

/// [NeonStorageGateway] backed by the S3-compatible Neon Object Storage API
/// over `package:http`. Requests are SigV4-signed and use path-style
/// addressing (`endpoint/bucket/key`).
final class S3NeonStorageGateway implements NeonStorageGateway {
  S3NeonStorageGateway({
    required NeonStorageConfig config,
    http.Client? client,
    NeonS3Signer? signer,
  }) : _config = config,
       _client = client ?? http.Client(),
       _signer =
           signer ??
           NeonS3Signer(
             region: config.region,
             accessKeyId: config.accessKeyId,
             secretAccessKey: config.secretAccessKey,
           );

  final NeonStorageConfig _config;
  final http.Client _client;
  final NeonS3Signer _signer;

  /// Releases the underlying HTTP client.
  void close() => _client.close();

  @override
  Future<void> upload(
    String key,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata = const <String, String>{},
    ProgressCallback? onProgress,
  }) async {
    final uri = _config.objectUri(key);
    final headers = <String, String>{
      'content-type': contentType ?? 'application/octet-stream',
      for (final entry in metadata.entries) 'x-amz-meta-${entry.key}': entry.value,
    };
    final signed = _signer.sign(
      method: 'PUT',
      url: uri,
      payload: bytes,
      headers: headers,
    );
    final response = await _client.put(uri, headers: signed, body: bytes);
    _ensureOk(response, FailureCode.fileUploadFailed);
    onProgress?.call(1);
  }

  @override
  Future<List<int>> download(
    String key, {
    ProgressCallback? onProgress,
  }) async {
    final uri = _config.objectUri(key);
    final signed = _signer.sign(method: 'GET', url: uri);
    final response = await _client.get(uri, headers: signed);
    _ensureOk(response, FailureCode.fileDownloadFailed);
    onProgress?.call(1);
    return response.bodyBytes;
  }

  @override
  Future<Uri> createSignedUrl(String key, Duration expiresIn) async {
    return _signer.presign(url: _config.objectUri(key), expires: expiresIn);
  }

  @override
  Future<void> delete(String key) async {
    final uri = _config.objectUri(key);
    final signed = _signer.sign(method: 'DELETE', url: uri);
    final response = await _client.delete(uri, headers: signed);
    _ensureOk(response, FailureCode.fileDeleteFailed);
  }

  void _ensureOk(http.Response response, FailureCode fallback) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return;
    }
    throw _storageFailure(status, response.body, fallback);
  }

  Failure _storageFailure(int status, String body, FailureCode fallback) {
    final code = status == 404 ? FailureCode.fileNotFound : fallback;
    return Failure(
      code: code,
      message: _describe(body, status),
      kind: FailureKind.storage,
      details: <String, Object?>{'statusCode': status},
    );
  }

  String _describe(String body, int status) {
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['message'] is String) {
          return decoded['message'] as String;
        }
      } on FormatException {
        // S3 errors are XML; fall through to the status summary.
      }
    }
    return 'The Neon Object Storage request failed with status $status.';
  }
}
