import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'checksum_verifier.dart';
import 'kiln_store_exception.dart';
import 'local_cache.dart';
import 'registry_config.dart';
import 'registry_index.dart';

/// Fetches registry indexes and extension archives over HTTP, `file:`, or a
/// local filesystem path.
final class RegistryClient {
  RegistryClient({required this.config, http.Client? httpClient, this.cache})
    : _http = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null {
    if (cache != null && cache!.registryIdentity != config.identity) {
      throw const KilnStoreException(
        'Cache belongs to a different registry.', code: 'store.invalid_config',
      );
    }
  }

  final RegistryConfig config;
  final LocalCache? cache;
  final http.Client _http;
  final bool _ownsHttpClient;

  /// Fetches and parses `index.json`.
  ///
  /// With [useMirror] the mirror is tried first. Otherwise the main registry is
  /// tried first and the mirror, when configured, is used as a fallback.
  /// Non-200 responses and network/filesystem failures raise
  /// `store.fetch_failed`.
  Future<RegistryIndex> fetchIndex({bool useMirror = false}) async {
    final mirrorUri = config.mirrorIndexUri;
    final candidates = <Uri>[
      if (useMirror && mirrorUri != null) mirrorUri else config.indexUri,
      if (!useMirror && mirrorUri != null) mirrorUri,
    ];

    KilnStoreException? failure;
    StackTrace? failureStack;
    for (final uri in candidates) {
      try {
        final bytes = await _fetchBytes(uri);
        final index = RegistryIndex.parse(utf8.decode(bytes));
        cache?.writeIndex(index);
        return index;
      } on Object catch (error, stack) {
        failure = error is KilnStoreException
            ? error
            : KilnStoreException(
                'Could not read the registry index.',
                code: 'store.fetch_failed',
                details: <String, Object?>{'uri': uri.toString()},
              );
        failureStack = stack;
      }
    }

    final error = failure;
    if (error == null) {
      throw const KilnStoreException(
        'No registry index location is configured.',
        code: 'store.fetch_failed',
      );
    }
    Error.throwWithStackTrace(error, failureStack ?? StackTrace.current);
  }

  /// Downloads [version] of [extensionId], verifies its SHA-256, and caches it.
  Future<List<int>> downloadArchive(
    String extensionId,
    RegistryVersion version, {
    required Uri indexUri,
  }) async {
    final uri = version.resolveUrl(indexUri);
    final bytes = await _fetchBytes(uri);
    const ChecksumVerifier().verify(bytes, version.sha256);
    cache?.writeArchive(extensionId, version.version, bytes);
    return bytes;
  }

  /// Releases the internally created HTTP client.
  void close() {
    if (_ownsHttpClient) {
      _http.close();
    }
  }

  Future<List<int>> _fetchBytes(Uri uri) async {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'file') {
      final file = File.fromUri(uri);
      try {
        if (!file.existsSync()) {
          throw KilnStoreException(
            'Registry file does not exist: ${file.path}',
            code: 'store.fetch_failed',
            suggestion: 'Check the configured registry path.',
            details: <String, Object?>{'uri': uri.toString()},
          );
        }
        return await file.readAsBytes();
      } on KilnStoreException {
        rethrow;
      } on Object catch (error) {
        throw KilnStoreException(
          'Could not read registry file ${file.path}: $error',
          code: 'store.fetch_failed',
          details: <String, Object?>{'uri': uri.toString()},
        );
      }
    }

    if (scheme == 'http' || scheme == 'https') {
      final http.Response response;
      try {
        response = await _http.get(uri);
      } on Object catch (error) {
        throw KilnStoreException(
          'Could not reach registry at $uri: $error',
          code: 'store.fetch_failed',
          suggestion: 'Check the URL and your network connection.',
          details: <String, Object?>{'uri': uri.toString()},
        );
      }
      if (response.statusCode != 200) {
        throw KilnStoreException(
          'Registry request to $uri returned HTTP ${response.statusCode}.',
          code: 'store.fetch_failed',
          suggestion: 'Check that the registry URL and ref are correct.',
          details: <String, Object?>{
            'uri': uri.toString(),
            'status': response.statusCode,
          },
        );
      }
      return response.bodyBytes;
    }

    throw KilnStoreException(
      'Unsupported registry URL scheme "${uri.scheme}".',
      code: 'store.fetch_failed',
      suggestion: 'Use HTTP(S), a file: URI, or a local directory.',
      details: <String, Object?>{'uri': uri.toString()},
    );
  }
}
