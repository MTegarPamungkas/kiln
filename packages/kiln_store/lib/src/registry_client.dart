import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'checksum_verifier.dart';
import 'kiln_store_exception.dart';
import 'local_cache.dart';
import 'registry_config.dart';
import 'registry_index.dart';

/// Fetches registry indexes and extension archives over HTTP, `file:`, or a
/// local filesystem path.
final class RegistryClient {
  RegistryClient({
    required this.config,
    http.Client? httpClient,
    this.cache,
    this.requestTimeout = const Duration(seconds: 15),
    this.maxDownloadBytes = 20 * 1024 * 1024,
  }) : _http = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null {
    if (cache != null && cache!.registryIdentity != config.identity) {
      throw const KilnStoreException(
        'Cache belongs to a different registry.',
        code: 'store.invalid_config',
      );
    }
  }

  final RegistryConfig config;
  final LocalCache? cache;
  final http.Client _http;
  final bool _ownsHttpClient;

  /// Upper bound for one registry request and its response body.
  final Duration requestTimeout;
  final int maxDownloadBytes;

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
        return await _readBounded(file.openRead(), uri);
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
      final abort = Completer<void>();
      try {
        response = await (() async {
          final streamed = await _http.send(
            http.AbortableRequest('GET', uri, abortTrigger: abort.future),
          );
          final contentLength = streamed.contentLength;
          if (contentLength != null && contentLength > maxDownloadBytes) {
            await streamed.stream.listen(null).cancel();
            throw _tooLarge(uri);
          }
          final bytes = await _readBounded(streamed.stream, uri);
          return http.Response.bytes(
            bytes,
            streamed.statusCode,
            headers: streamed.headers,
            request: streamed.request,
          );
        })().timeout(requestTimeout);
      } on TimeoutException {
        if (!abort.isCompleted) abort.complete();
        throw KilnStoreException(
          'Registry request to $uri timed out after ${requestTimeout.inSeconds}s.',
          code: 'store.fetch_failed',
          suggestion: 'Check the URL and your network connection.',
          details: <String, Object?>{'uri': uri.toString()},
        );
      } on KilnStoreException {
        rethrow;
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

  KilnStoreException _tooLarge(Uri uri) => KilnStoreException(
    'Registry response from $uri is larger than $maxDownloadBytes bytes.',
    code: 'store.fetch_failed',
    details: {'uri': uri.toString()},
  );

  Future<List<int>> _readBounded(Stream<List<int>> stream, Uri uri) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > maxDownloadBytes) {
        throw _tooLarge(uri);
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }
}
