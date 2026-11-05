import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kiln_core/kiln_core.dart';

/// AWS Signature Version 4 signer for S3-compatible endpoints (Neon Object
/// Storage uses path-style addressing and SigV4 only).
///
/// The algorithm is the standard AWS one; it is exercised against the official
/// AWS SigV4 conformance vectors in tests. [clock] is injectable so a signature
/// can be reproduced from a fixed timestamp.
final class NeonS3Signer {
  NeonS3Signer({
    required this.region,
    required this.accessKeyId,
    required this.secretAccessKey,
    this.service = 's3',
    this.clock = const SystemClock(),
  });

  static const String _emptySha256 =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  final String region;
  final String service;
  final String accessKeyId;
  final String secretAccessKey;
  final Clock clock;

  /// Signs a request for S3, adding `host`, `x-amz-date`, and
  /// `x-amz-content-sha256` and returning the header set including
  /// `Authorization`.
  Map<String, String> sign({
    required String method,
    required Uri url,
    List<int> payload = const <int>[],
    Map<String, String> headers = const <String, String>{},
  }) {
    final amzDate = _amzDate(clock.now());
    final payloadHash = payload.isEmpty
        ? _emptySha256
        : _hex(sha256.convert(payload).bytes);
    final all = <String, String>{
      'host': _host(url),
      ...headers,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
    };
    return <String, String>{
      ...all,
      'Authorization': authorization(
        method: method,
        url: url,
        headers: all,
        payloadHash: payloadHash,
      ),
    };
  }

  /// Builds the `Authorization` header from the exact [headers] to sign. The
  /// caller supplies `host` and `x-amz-date`, which lets the AWS test vectors be
  /// reproduced without the S3-specific `x-amz-content-sha256` header.
  String authorization({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    required String payloadHash,
  }) {
    final lower = <String, String>{
      for (final entry in headers.entries)
        entry.key.toLowerCase(): entry.value.trim(),
    };
    final names = lower.keys.toList()..sort();
    final canonicalHeaders = [
      for (final name in names) '$name:${lower[name]}\n',
    ].join();
    final signedHeaders = names.join(';');
    final amzDate = lower['x-amz-date'] ?? _amzDate(clock.now());
    final dateStamp = amzDate.substring(0, 8);
    final scope = '$dateStamp/$region/$service/aws4_request';
    final canonicalRequest = <String>[
      method.toUpperCase(),
      _canonicalUri(url),
      _canonicalQuery(url),
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');
    final stringToSign = <String>[
      'AWS4-HMAC-SHA256',
      amzDate,
      scope,
      _hex(sha256.convert(utf8.encode(canonicalRequest)).bytes),
    ].join('\n');
    final signature = _hex(
      Hmac(sha256, _signingKey(dateStamp)).convert(utf8.encode(stringToSign)).bytes,
    );
    return 'AWS4-HMAC-SHA256 Credential=$accessKeyId/$scope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';
  }

  /// Returns a pre-signed GET URL valid for [expires], suitable for handing to
  /// an image or download widget. The payload is `UNSIGNED-PAYLOAD`.
  Uri presign({
    required Uri url,
    required Duration expires,
    String method = 'GET',
  }) {
    final now = clock.now();
    final amzDate = _amzDate(now);
    final dateStamp = amzDate.substring(0, 8);
    final scope = '$dateStamp/$region/$service/aws4_request';
    final existing = <String, String>{
      for (final entry in url.queryParametersAll.entries)
        entry.key: entry.value.join(','),
    };
    final params = <String, String>{
      ...existing,
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '$accessKeyId/$scope',
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': '${expires.inSeconds}',
      'X-Amz-SignedHeaders': 'host',
    };
    final canonicalQuery = _encodedQuery(params);
    final canonicalRequest = <String>[
      method.toUpperCase(),
      _canonicalUri(url),
      canonicalQuery,
      'host:${_host(url)}\n',
      'host',
      'UNSIGNED-PAYLOAD',
    ].join('\n');
    final stringToSign = <String>[
      'AWS4-HMAC-SHA256',
      amzDate,
      scope,
      _hex(sha256.convert(utf8.encode(canonicalRequest)).bytes),
    ].join('\n');
    final signature = _hex(
      Hmac(sha256, _signingKey(dateStamp)).convert(utf8.encode(stringToSign)).bytes,
    );
    final query = '$canonicalQuery&X-Amz-Signature=${_uriEncode(signature, encodeSlash: true)}';
    return Uri.parse('${url.scheme}://${_host(url)}${_canonicalUri(url)}?$query');
  }

  List<int> _signingKey(String dateStamp) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$secretAccessKey'))
        .convert(utf8.encode(dateStamp))
        .bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
  }

  String _canonicalUri(Uri url) {
    final path = url.path;
    return path.isEmpty ? '/' : path;
  }

  String _canonicalQuery(Uri url) {
    if (!url.hasQuery) {
      return '';
    }
    final pairs = <List<String>>[];
    for (final entry in url.queryParametersAll.entries) {
      for (final value in entry.value) {
        pairs.add(<String>[
          _uriEncode(entry.key, encodeSlash: true),
          _uriEncode(value, encodeSlash: true),
        ]);
      }
    }
    pairs.sort((a, b) {
      final key = a[0].compareTo(b[0]);
      return key != 0 ? key : a[1].compareTo(b[1]);
    });
    return pairs.map((pair) => '${pair[0]}=${pair[1]}').join('&');
  }

  String _encodedQuery(Map<String, String> params) {
    final pairs = <List<String>>[
      for (final entry in params.entries)
        <String>[
          _uriEncode(entry.key, encodeSlash: true),
          _uriEncode(entry.value, encodeSlash: true),
        ],
    ];
    pairs.sort((a, b) {
      final key = a[0].compareTo(b[0]);
      return key != 0 ? key : a[1].compareTo(b[1]);
    });
    return pairs.map((pair) => '${pair[0]}=${pair[1]}').join('&');
  }

  static String _host(Uri url) {
    final port = url.port;
    final isDefault = (url.scheme == 'https' && port == 443) ||
        (url.scheme == 'http' && port == 80);
    return url.hasPort && !isDefault ? '${url.host}:$port' : url.host;
  }

  static String _amzDate(DateTime value) {
    final dt = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}'
        'T${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// AWS URI-encoding: unreserved characters pass through, everything else is
  /// percent-encoded in uppercase; `/` is kept only when [encodeSlash] is false.
  static String _uriEncode(String input, {required bool encodeSlash}) {
    final result = StringBuffer();
    for (final byte in utf8.encode(input)) {
      final isUnreserved = (byte >= 0x41 && byte <= 0x5A) || // A-Z
          (byte >= 0x61 && byte <= 0x7A) || // a-z
          (byte >= 0x30 && byte <= 0x39) || // 0-9
          byte == 0x2D || // -
          byte == 0x2E || // .
          byte == 0x5F || // _
          byte == 0x7E; // ~
      if (isUnreserved) {
        result.write(String.fromCharCode(byte));
      } else if (byte == 0x2F && !encodeSlash) {
        result.write('/');
      } else {
        result.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return result.toString();
  }

  /// Encodes an object key for a path-style URL, preserving `/` separators.
  static String encodeObjectPath(String key) {
    final segments = key.split('/').map((s) => _uriEncode(s, encodeSlash: false));
    return segments.join('/');
  }
}
