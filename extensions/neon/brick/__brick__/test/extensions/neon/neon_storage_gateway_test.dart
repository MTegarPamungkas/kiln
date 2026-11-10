import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_token_provider.dart';

const _config = NeonStorageConfig(
  signingUrl: 'https://signing.example.test/storage/sign',
  bucket: 'files',
);

const _objectUrl = 'https://objects.example.test/files/a/b.txt?X-Amz-Signature=abc';

final class _Signer {
  _Signer(this.response);

  final Map<String, Object?> Function(http.Request request) response;
  final List<http.Request> signingRequests = <http.Request>[];
  final List<http.Request> objectRequests = <http.Request>[];

  MockClient get client => MockClient((request) async {
    if (request.url.host == 'signing.example.test') {
      signingRequests.add(request);
      return http.Response(jsonEncode(response(request)), 200,
          headers: {'content-type': 'application/json'});
    }
    objectRequests.add(request);
    return http.Response.bytes(const <int>[1, 2, 3], 200);
  });
}

PresignedNeonStorageGateway _gateway(
  MockClient client, {
  NeonTokenProvider? tokens,
}) => PresignedNeonStorageGateway(
  config: _config,
  tokenProvider: tokens ?? StaticNeonTokenProvider('user-jwt'),
  client: client,
);

void main() {
  test('upload sends the user JWT only to the signing backend', () async {
    final signer = _Signer((_) => <String, Object?>{
      'url': _objectUrl,
      'headers': <String, Object?>{'content-type': 'text/plain', 'x-amz-meta-owner': 'tegar'},
    });
    final gateway = _gateway(signer.client);

    await gateway.upload('a/b.txt', <int>[9, 8],
        contentType: 'text/plain', metadata: <String, String>{'owner': 'tegar'});

    final presign = signer.signingRequests.single;
    expect(presign.method, 'POST');
    expect(presign.headers['Authorization'], 'Bearer user-jwt');
    expect(presign.followRedirects, isFalse);
    final body = jsonDecode(presign.body) as Map<String, Object?>;
    expect(body, <String, Object?>{
      'operation': 'upload',
      'bucket': 'files',
      'key': 'a/b.txt',
      'contentType': 'text/plain',
      'metadata': <String, Object?>{'owner': 'tegar'},
      'expiresIn': 300,
    });

    final put = signer.objectRequests.single;
    expect(put.method, 'PUT');
    expect(put.url.toString(), _objectUrl);
    expect(put.headers.containsKey('Authorization'), isFalse);
    expect(put.headers['content-type'], 'text/plain');
    expect(put.bodyBytes, <int>[9, 8]);
  });

  test('download and delete use their signed methods', () async {
    final signer = _Signer((request) => <String, Object?>{'url': _objectUrl});
    final gateway = _gateway(signer.client);

    expect(await gateway.download('a/b.txt'), <int>[1, 2, 3]);
    await gateway.delete('a/b.txt');

    expect(signer.signingRequests.map((request) => request.method), ['POST', 'POST']);
    expect(signer.objectRequests.map((request) => request.method), ['GET', 'DELETE']);
  });

  test('createSignedUrl refuses headers it cannot deliver to the caller', () async {
    final signer = _Signer((_) => <String, Object?>{
      'url': _objectUrl,
      'headers': <String, Object?>{'x-amz-meta-owner': 'tegar'},
    });
    final gateway = _gateway(signer.client);

    await expectLater(
      gateway.createSignedUrl('a/b.txt', const Duration(minutes: 1)),
      throwsA(isA<Failure>()),
    );
    expect(signer.objectRequests, isEmpty);
  });

  test('createSignedUrl returns the scoped object URL', () async {
    final signer = _Signer((request) {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['operation'], 'download');
      expect(body['expiresIn'], 60);
      return <String, Object?>{'url': _objectUrl};
    });

    final url = await _gateway(signer.client)
        .createSignedUrl('a/b.txt', const Duration(minutes: 1));

    expect(url, Uri.parse(_objectUrl));
  });

  test('a signing rejection maps to a stable failure', () async {
    final client = MockClient((_) async => http.Response('{"message":"no"}', 403));
    final gateway = _gateway(client);

    await expectLater(
      gateway.download('a.txt'),
      throwsA(isA<Failure>().having((f) => f.code, 'code', FailureCode.permissionDenied)),
    );
  });

  test('an unsigned user cannot obtain a URL', () async {
    var requests = 0;
    final signer = _Signer((_) {
      requests++;
      return <String, Object?>{'url': _objectUrl};
    });
    final gateway = _gateway(signer.client, tokens: StaticNeonTokenProvider(''));

    await expectLater(
      gateway.download('a.txt'),
      throwsA(isA<Failure>().having((f) => f.code, 'code', FailureCode.authUnauthorized)),
    );
    expect(requests, 0);
  });

  test('a missing object is fileNotFound', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'signing.example.test') {
        return http.Response(jsonEncode(<String, Object?>{'url': _objectUrl}), 200);
      }
      return http.Response('', 404);
    });

    await expectLater(
      _gateway(client).download('gone.txt'),
      throwsA(isA<Failure>().having((f) => f.code, 'code', FailureCode.fileNotFound)),
    );
  });

  test('malformed signing responses are rejected', () async {
    for (final payload in <Map<String, Object?>>[
      <String, Object?>{'url': 'http://objects.example.test/a.txt'},
      <String, Object?>{'url': '/files/a.txt'},
      <String, Object?>{'url': 'https://user:pass@objects.example.test/a.txt'},
      <String, Object?>{'url': 'https://objects.example.test/a.txt?token=user-jwt'},
      <String, Object?>{'url': _objectUrl, 'headers': <String, Object?>{'Authorization': 'Bearer x'}},
      <String, Object?>{'url': _objectUrl, 'headers': <String, Object?>{'x-amz-meta-owner': 'user-jwt'}},
    ]) {
      final signer = _Signer((_) => payload);
      await expectLater(
        _gateway(signer.client).download('a.txt'),
        throwsA(isA<Failure>()),
        reason: '$payload',
      );
      expect(signer.objectRequests, isEmpty, reason: '$payload');
    }
  });

  test('unsafe keys and lifetimes are rejected before any request', () async {
    var requests = 0;
    final signer = _Signer((_) {
      requests++;
      return <String, Object?>{'url': _objectUrl};
    });
    final gateway = _gateway(signer.client);

    for (final key in <String>['', '../secret', 'a/./b', '/absolute', 'a\\b', 'a\x00b']) {
      await expectLater(gateway.download(key), throwsA(isA<Failure>()), reason: key);
    }
    await expectLater(
      gateway.createSignedUrl('a.txt', const Duration(hours: 1)),
      throwsA(isA<Failure>()),
    );
    expect(requests, 0);
  });
}
