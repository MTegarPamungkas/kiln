import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_session_token_provider.dart';
import 'package:{{app_name}}/extensions/neon/neon_token_provider.dart';

import 'test_support.dart';

String _jwt(int exp) {
  final header =
      base64Url.encode(utf8.encode('{"alg":"HS256"}')).replaceAll('=', '');
  final payload =
      base64Url.encode(utf8.encode('{"role":"anonymous","exp":$exp}'))
          .replaceAll('=', '');
  return '$header.$payload.sig';
}

void main() {
  test('the static provider returns its token', () async {
    final provider = StaticNeonTokenProvider('abc');

    expect(await provider.token(), 'abc');
  });

  test('the anonymous provider fetches from token/anonymous and caches', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.path, '/db/auth/token/anonymous');
      expect(request.headers['origin'], 'https://auth.test');
      return http.Response(jsonEncode(<String, Object?>{'token': _jwt(2000000000)}), 200);
    });
    final provider = NeonAnonymousTokenProvider(
      authUrl: 'https://auth.test/db/auth',
      client: client,
      clock: FixedClock(DateTime.utc(2024)),
    );

    expect(await provider.token(), _jwt(2000000000));
    expect(await provider.token(), _jwt(2000000000));
    expect(calls, 1);
  });

  test('the anonymous provider refetches once the token expires', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response(jsonEncode(<String, Object?>{'token': _jwt(2000000000)}), 200);
    });
    final clock = FixedClock(DateTime.utc(2024));
    final provider = NeonAnonymousTokenProvider(
      authUrl: 'https://auth.test/db/auth',
      client: client,
      clock: clock,
    );

    await provider.token();
    clock.set(
      DateTime.fromMillisecondsSinceEpoch(2000000000 * 1000)
          .add(const Duration(minutes: 2)),
    );
    await provider.token();

    expect(calls, 2);
  });

  test('a non-2xx anonymous token response throws', () async {
    final provider = NeonAnonymousTokenProvider(
      authUrl: 'https://auth.test/db/auth',
      client: MockClient((request) async => http.Response('{}', 503)),
    );

    await expectLater(
      provider.token(),
      throwsA(
        isA<NeonApiException>().having(
          (value) => value.statusCode,
          'statusCode',
          503,
        ),
      ),
    );
  });

  test('closing the session provider closes a disposable fallback', () {
    final anonymousClient = RecordingClient();
    final provider = NeonSessionTokenProvider(
      auth: FakeNeonAuthGateway(),
      fallback: NeonAnonymousTokenProvider(
        authUrl: 'https://auth.test/db/auth',
        client: anonymousClient,
      ),
    );

    provider.close();

    expect(anonymousClient.closeCalls, 1);
  });

  test('closing the session provider tolerates a static or absent fallback',
      () {
    NeonSessionTokenProvider(
      auth: FakeNeonAuthGateway(),
      fallback: StaticNeonTokenProvider('abc'),
    ).close();
    NeonSessionTokenProvider(auth: FakeNeonAuthGateway()).close();
  });
}

/// A client that counts `close()` calls so disposal can be asserted.
final class RecordingClient extends http.BaseClient {
  int closeCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream.value(<int>[]), 200);
  }

  @override
  void close() => closeCalls++;
}
