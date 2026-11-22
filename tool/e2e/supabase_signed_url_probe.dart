// K11 live check: Supabase Storage signed-URL lifetimes on a local stack.
//
// The extension's `SupabaseFileStorage.url` delegates to the Storage API, so the
// remaining acceptance item is provider behaviour: a signed link must work for
// the requested lifetime and stop working afterwards. This probe drives the
// Storage API directly so it needs no rendered app.
//
//   $env:KILN_SUPABASE_URL = 'http://127.0.0.1:54321'
//   $env:KILN_SUPABASE_SERVICE_KEY = '<local service_role key>'
//   $env:KILN_SUPABASE_ANON_KEY = '<local anon key>'
//   dart run tool/e2e/supabase_signed_url_probe.dart
//
// The stack's default keys are local-only. Bucket and object are created per run
// with a unique name and deleted afterwards.

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final base = Platform.environment['KILN_SUPABASE_URL'] ?? '';
  final serviceKey = Platform.environment['KILN_SUPABASE_SERVICE_KEY'] ?? '';
  final anonKey = Platform.environment['KILN_SUPABASE_ANON_KEY'] ?? '';
  if (base.isEmpty || serviceKey.isEmpty || anonKey.isEmpty) {
    stderr.writeln(
      'Set KILN_SUPABASE_URL, KILN_SUPABASE_SERVICE_KEY and KILN_SUPABASE_ANON_KEY.',
    );
    exitCode = 2;
    return;
  }

  final probe = _Probe(base, serviceKey);
  try {
    await probe.run(anonKey: anonKey);
  } finally {
    probe.close();
  }
  if (probe.failures.isNotEmpty) {
    stderr.writeln('${probe.failures.length} assertion(s) failed');
    exitCode = 1;
  }
}

final class _Probe {
  _Probe(this.base, this.serviceKey)
    : _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  final String base;
  final String serviceKey;
  final HttpClient _client;
  final List<String> failures = <String>[];
  int _checks = 0;

  void close() => _client.close(force: true);

  Future<void> run({required String anonKey}) async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final bucket = 'kiln-signed-$suffix';
    final path = 'probe.txt';
    final body = 'signed-url-probe-$suffix';

    try {
      final created = await _request(
        'POST',
        '/storage/v1/bucket',
        key: serviceKey,
        json: {'id': bucket, 'name': bucket, 'public': false},
      );
      _expect('service role creates a private bucket', created.status == 200, created.raw);

      final uploaded = await _request(
        'POST',
        '/storage/v1/object/$bucket/$path',
        key: serviceKey,
        headers: {'content-type': 'text/plain', 'x-upsert': 'true'},
        rawBody: body,
      );
      _expect('service role uploads an object', uploaded.status == 200, uploaded.raw);

      final shortLived = await _sign(bucket, path, 3, key: serviceKey);
      _expect('short-lived link is issued', shortLived.url != null, shortLived.raw);
      final shortUrl = shortLived.url;

      if (shortUrl != null) {
        final fresh = await _get(shortUrl);
        _expect(
          'short-lived link serves the object before expiry',
          fresh.status == 200 && fresh.raw == body,
          'status=${fresh.status} body=${fresh.raw}',
        );

        _expect(
          'short-lived link is rejected after expiry',
          await _waitForExpiry(shortUrl, seconds: 3),
        );
      }

      final longLived = await _sign(
        bucket,
        path,
        const Duration(hours: 1).inSeconds,
        key: serviceKey,
      );
      _expect('one-hour link is issued', longLived.url != null, longLived.raw);
      if (longLived.url != null) {
        final served = await _get(longLived.url!);
        _expect(
          'one-hour link still serves the object',
          served.status == 200 && served.raw == body,
          'status=${served.status} body=${served.raw}',
        );
      }

      final anonymousSign = await _request(
        'POST',
        '/storage/v1/object/sign/$bucket/$path',
        key: anonKey,
        json: {'expiresIn': 60},
      );
      _expect(
        'anonymous key cannot sign without a storage policy',
        anonymousSign.status >= 400,
        'status=${anonymousSign.status} body=${anonymousSign.raw}',
      );
    } finally {
      await _request(
        'DELETE',
        '/storage/v1/object/$bucket/$path',
        key: serviceKey,
      );
      await _request('DELETE', '/storage/v1/bucket/$bucket', key: serviceKey);
    }

    stdout.writeln(
      '$_checks checks, ${failures.length} failed'
      '${failures.isEmpty ? ' - signed URL lifetimes hold' : ''}',
    );
    for (final failure in failures) {
      stdout.writeln('FAIL: $failure');
    }
  }

  Future<bool> _waitForExpiry(String url, {required int seconds}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds + 2));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final response = await _get(url);
      if (response.status >= 400) {
        return true;
      }
    }
    return false;
  }

  Future<_SignedUrl> _sign(
    String bucket,
    String path,
    int expiresIn, {
    required String key,
  }) async {
    final response = await _request(
      'POST',
      '/storage/v1/object/sign/$bucket/$path',
      key: key,
      json: {'expiresIn': expiresIn},
    );
    final decoded = response.raw.isEmpty ? null : jsonDecode(response.raw);
    final signed = decoded is Map<String, Object?> ? decoded['signedURL'] : null;
    if (signed is! String) {
      return _SignedUrl(null, response.raw);
    }
    final relative = signed.startsWith('/') ? signed : '/$signed';
    final full = relative.startsWith('/storage/v1/')
        ? relative
        : '/storage/v1$relative';
    return _SignedUrl(Uri.parse(base).resolve(full).toString(), response.raw);
  }

  void _expect(String label, bool ok, [String? actual]) {
    _checks += 1;
    if (ok) {
      stdout.writeln('ok   $label');
    } else {
      failures.add('$label${actual == null ? '' : ' ($actual)'}');
      stdout.writeln('FAIL $label${actual == null ? '' : ' ($actual)'}');
    }
  }

  Future<_Result> _get(String url) async {
    final request = await _client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Result(response.statusCode, body);
  }

  Future<_Result> _request(
    String method,
    String path, {
    required String key,
    Map<String, String> headers = const {},
    Map<String, Object?>? json,
    String? rawBody,
  }) async {
    final request = await _client.openUrl(method, Uri.parse('$base$path'));
    request.headers.set('apikey', key);
    request.headers.set('authorization', 'Bearer $key');
    headers.forEach(request.headers.set);
    if (json != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(json));
    } else if (rawBody != null) {
      request.write(rawBody);
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Result(response.statusCode, body);
  }
}

final class _SignedUrl {
  _SignedUrl(this.url, this.raw);

  final String? url;
  final String raw;
}

final class _Result {
  _Result(this.status, this.raw);

  final int status;
  final String raw;
}
