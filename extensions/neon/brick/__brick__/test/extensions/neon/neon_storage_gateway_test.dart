import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_gateway.dart';

void main() {
  const config = NeonStorageConfig(
    endpoint: 'https://demo.storage.c-us-east-2.aws.neon.tech',
    bucket: 'files',
    region: 'us-east-2',
    accessKeyId: 'token-id',
    secretAccessKey: 's3-secret',
  );

  S3NeonStorageGateway gatewayReturning(
    int status, {
    List<int> body = const <int>[],
    void Function(http.Request)? onRec,
  }) {
    return S3NeonStorageGateway(
      config: config,
      client: MockClient((request) async {
        onRec?.call(request);
        return http.Response.bytes(body, status);
      }),
    );
  }

  test('upload signs a path-style PUT and returns success', () async {
    http.Request? seen;
    final gateway = gatewayReturning(
      200,
      onRec: (request) => seen = request,
    );

    await gateway.upload(
      'a/b.txt',
      <int>[1, 2, 3],
      contentType: 'text/plain',
      metadata: <String, String>{'owner': 'tegar'},
    );

    expect(seen!.method, 'PUT');
    expect(seen!.url.path, '/files/a/b.txt');
    expect(seen!.headers['content-type'], 'text/plain');
    expect(seen!.headers['x-amz-meta-owner'], 'tegar');
    expect(seen!.headers['Authorization'], startsWith('AWS4-HMAC-SHA256'));
    expect(
      seen!.headers['Authorization'],
      contains('Credential=token-id/'),
    );
    expect(seen!.bodyBytes, <int>[1, 2, 3]);
  });

  test('download returns the object bytes', () async {
    final gateway = gatewayReturning(
      200,
      body: utf8.encode('hello'),
    );

    expect(await gateway.download('a.txt'), utf8.encode('hello'));
  });

  test('a missing object is fileNotFound', () async {
    final gateway = gatewayReturning(404);

    await expectLater(
      gateway.download('gone.txt'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileNotFound,
        ),
      ),
    );
  });

  test('delete succeeds on 204', () async {
    http.Request? seen;
    final gateway = gatewayReturning(204, onRec: (r) => seen = r);

    await gateway.delete('a.txt');

    expect(seen!.method, 'DELETE');
    expect(seen!.url.path, '/files/a.txt');
  });

  test('a server error maps to the operation failure code', () async {
    final gateway = gatewayReturning(500);

    await expectLater(
      gateway.delete('a.txt'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.fileDeleteFailed,
        ),
      ),
    );
  });

  test('createSignedUrl returns a presigned URL without a request', () async {
    var touched = false;
    final gateway = S3NeonStorageGateway(
      config: config,
      client: MockClient((request) async {
        touched = true;
        return http.Response('', 200);
      }),
    );

    final uri = await gateway.createSignedUrl('a/b.txt', const Duration(minutes: 5));

    expect(touched, isFalse);
    expect(uri.queryParameters['X-Amz-Signature'], isNotNull);
    expect(uri.path, '/files/a/b.txt');
  });
}
