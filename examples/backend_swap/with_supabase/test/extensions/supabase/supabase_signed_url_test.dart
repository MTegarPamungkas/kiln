// Live signed-URL check for a local Supabase stack (K11).
//
// The unit tests cover the extension's own validation; this one covers the
// provider decision the contract depends on: a signed link works for the
// requested lifetime, and stops working afterwards. It uses the real Storage API
// through the `supabase` client that `supabase_flutter` re-exports, plus the
// extension's own `resolveSupabaseSignedUrl` for the relative link shape.
//
// Skipped unless the environment opts in:
//
//   KILN_SUPABASE_LOCAL_STORAGE=1
//   KILN_SUPABASE_LOCAL_URL=http://127.0.0.1:54321
//   KILN_SUPABASE_LOCAL_ANON_KEY=<anon key>
//   KILN_SUPABASE_LOCAL_SERVICE_KEY=<service_role key>
//
// The service key creates the disposable bucket, uploads the object and signs
// the links; the signed URL itself is fetched without a session.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:with_supabase/extensions/supabase/supabase_storage_gateway.dart';

void main() {
  final environment = Platform.environment;
  final url = environment['KILN_SUPABASE_LOCAL_URL'] ?? '';
  final anonKey = environment['KILN_SUPABASE_LOCAL_ANON_KEY'] ?? '';
  final serviceKey = environment['KILN_SUPABASE_LOCAL_SERVICE_KEY'] ?? '';
  final enabled =
      environment['KILN_SUPABASE_LOCAL_STORAGE'] == '1' &&
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      serviceKey.isNotEmpty;
  final skipReason = enabled
      ? null
      : 'Set KILN_SUPABASE_LOCAL_STORAGE=1, KILN_SUPABASE_LOCAL_URL, '
            'KILN_SUPABASE_LOCAL_ANON_KEY and KILN_SUPABASE_LOCAL_SERVICE_KEY '
            'to run against a local stack.';

  group('local storage signed URLs', () {
    late SupabaseClient service;
    late String bucket;
    late String body;

    setUpAll(() async {
      if (!enabled) {
        return;
      }
      service = SupabaseClient(url, serviceKey);
      bucket = 'kiln-signed-${DateTime.now().microsecondsSinceEpoch}';
      body = 'signed-url-$bucket';
      await service.storage.createBucket(bucket);
      await service.storage
          .from(bucket)
          .uploadBinary('probe.txt', Uint8List.fromList(utf8.encode(body)));
    });

    tearDownAll(() async {
      if (!enabled) {
        return;
      }
      try {
        await service.storage.emptyBucket(bucket);
        await service.storage.deleteBucket(bucket);
      } on Object {
        // The bucket is disposable; a failed cleanup must not fail the suite.
      }
    });

    test('a short link serves the object, then expires', () async {
      final signed = await service.storage
          .from(bucket)
          .createSignedUrl('probe.txt', 2);
      final uri = resolveSupabaseSignedUrl(url, signed);

      expect(uri.path, startsWith('/storage/v1/object/sign/'));
      expect(uri.query, isNotEmpty);

      final fresh = await _get(uri);
      expect(fresh.status, 200);
      expect(fresh.body, body);

      expect(await _waitUntilRejected(uri, seconds: 5), isTrue);
    }, skip: skipReason);

    test('a one-hour link still serves the object', () async {
      final signed = await service.storage
          .from(bucket)
          .createSignedUrl('probe.txt', 3600);
      final uri = resolveSupabaseSignedUrl(url, signed);

      final served = await _get(uri);
      expect(served.status, 200);
      expect(served.body, body);
    }, skip: skipReason);

    test('the anon key alone cannot sign', () async {
      final anonymous = SupabaseClient(url, anonKey);

      await expectLater(
        anonymous.storage.from(bucket).createSignedUrl('probe.txt', 60),
        throwsA(anything),
      );
    }, skip: skipReason);
  });
}

Future<bool> _waitUntilRejected(Uri uri, {required int seconds}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final response = await _get(uri);
    if (response.status >= 400) {
      return true;
    }
  }
  return false;
}

Future<_Response> _get(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Response(response.statusCode, body);
  } finally {
    client.close(force: true);
  }
}

final class _Response {
  const _Response(this.status, this.body);

  final int status;
  final String body;
}
