import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_auth_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_session_token_provider.dart';
import 'package:{{app_name}}/extensions/neon/neon_token_provider.dart';

void main() {
  const config = NeonConfig(
    dataApiUrl: 'https://demo.aws.neon.tech/sql/rest',
    apiKey: 'secret-token',
    schema: 'app',
  );

  HttpNeonGateway gatewayReturning(
    int status,
    String body, {
    void Function(http.Request)? onRec
  }) {
    return HttpNeonGateway(
      config: config,
      client: MockClient((request) async {
        onRec?.call(request);
        return http.Response(
          body,
          status,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
  }

  test('insert posts a representation request and returns the row', () async {
    http.Request? seen;
    final gateway = gatewayReturning(
      201,
      jsonEncode(<Map<String, Object?>>[
        <String, Object?>{'id': '1', 'title': 'Write docs'},
      ]),
      onRec: (request) => seen = request,
    );

    final row = await gateway.insert('tasks', <String, Object?>{
      'title': 'Write docs',
    });

    expect(row['id'], '1');
    expect(seen!.method, 'POST');
    expect(seen!.url.path, endsWith('/tasks'));
    expect(seen!.headers['Authorization'], 'Bearer secret-token');
    expect(seen!.headers['Content-Profile'], 'app');
    expect(seen!.headers['Prefer'], 'return=representation');
    expect(jsonDecode(seen!.body), <String, Object?>{'title': 'Write docs'});
  });

  test('selectById filters on the id column', () async {
    http.Request? seen;
    final gateway = gatewayReturning(
      200,
      jsonEncode(<Map<String, Object?>>[
        <String, Object?>{'id': '7', 'name': 'Ada'},
      ]),
      onRec: (request) => seen = request,
    );

    final row = await gateway.selectById('users', '7');

    expect(row?['name'], 'Ada');
    expect(seen!.method, 'GET');
    expect(seen!.url.queryParameters['id'], 'eq.7');
    expect(seen!.headers['Accept-Profile'], 'app');
  });

  test('select encodes filters, order, limit, and offset', () async {
    http.Request? seen;
    final gateway = gatewayReturning(
      200,
      jsonEncode(<Map<String, Object?>>[]),
      onRec: (request) => seen = request,
    );

    await gateway.select(
      'tasks',
      query: const PostgrestQuery(
        filters: <PostgrestFilter>[
          PostgrestFilter('done', PostgrestOperator.equals, true),
          PostgrestFilter('tag', PostgrestOperator.inList, <Object?>['a', 'b']),
          PostgrestFilter('archived_at', PostgrestOperator.isNull),
        ],
        orderBy: <PostgrestOrder>[PostgrestOrder('title', ascending: false)],
        limit: 10,
        offset: 5,
      ),
    );

    final params = seen!.url.queryParameters;
    expect(params['done'], 'eq.true');
    expect(params['tag'], 'in("a","b")');
    expect(params['archived_at'], 'is.null');
    expect(params['order'], 'title.desc');
    expect(params['limit'], '10');
    expect(params['offset'], '5');
  });

  test('updateById patches the row and returns it', () async {
    http.Request? seen;
    final gateway = gatewayReturning(
      200,
      jsonEncode(<Map<String, Object?>>[
        <String, Object?>{'id': '3', 'name': 'Updated'},
      ]),
      onRec: (request) => seen = request,
    );

    final row = await gateway.updateById(
      'users',
      '3',
      <String, Object?>{'name': 'Updated'},
    );

    expect(row?['name'], 'Updated');
    expect(seen!.method, 'PATCH');
    expect(seen!.url.queryParameters['id'], 'eq.3');
  });

  test('deleteById reports whether a row was removed', () async {
    http.Request? seen;
    final gateway = gatewayReturning(
      200,
      jsonEncode(<Map<String, Object?>>[
        <String, Object?>{'id': '9'},
      ]),
      onRec: (request) => seen = request,
    );

    final deleted = await gateway.deleteById('users', '9');

    expect(deleted, isTrue);
    expect(seen!.method, 'DELETE');
  });

  test('an empty response body yields no rows', () async {
    final gateway = gatewayReturning(204, '');

    expect(await gateway.select('tasks'), isEmpty);
  });

  test('a 404 response maps to a notFound failure', () async {
    final gateway = gatewayReturning(404, jsonEncode({'message': 'missing'}));

    await expectLater(
      gateway.selectById('users', 'nope'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
  });

  test('closing the gateway releases a wrapped anonymous fallback client', () {
    final anonymousClient = RecordingClient();
    final gateway = HttpNeonGateway(
      config: config.copyWith(apiKey: '', authUrl: 'https://auth.test/db/auth'),
      client: MockClient((request) async => http.Response('[]', 200)),
      tokenProvider: NeonSessionTokenProvider(
        auth: BetterAuthGateway(
          authUrl: 'https://auth.test/db/auth',
          client: MockClient((request) async => http.Response('{}', 404)),
        ),
        fallback: NeonAnonymousTokenProvider(
          authUrl: 'https://auth.test/db/auth',
          client: anonymousClient,
        ),
      ),
    );

    gateway.close();

    expect(anonymousClient.closeCalls, 1);
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
