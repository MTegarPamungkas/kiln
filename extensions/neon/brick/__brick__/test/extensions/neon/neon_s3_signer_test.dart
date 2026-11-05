import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_s3_signer.dart';

void main() {
  const emptyPayloadHash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  // Signer configured to reproduce the official AWS SigV4 test suite vectors.
  final vector = NeonS3Signer(
    region: 'us-east-1',
    service: 'service',
    accessKeyId: 'AKIDEXAMPLE',
    secretAccessKey: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
    clock: FixedClock(DateTime.utc(2015, 8, 30, 12, 36, 0)),
  );

  test('matches the AWS get-vanilla vector', () {
    final auth = vector.authorization(
      method: 'GET',
      url: Uri.parse('https://example.amazonaws.com/'),
      headers: <String, String>{
        'host': 'example.amazonaws.com',
        'x-amz-date': '20150830T123600Z',
      },
      payloadHash: emptyPayloadHash,
    );

    expect(
      auth,
      'AWS4-HMAC-SHA256 '
      'Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, '
      'SignedHeaders=host;x-amz-date, '
      'Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31',
    );
  });

  test('matches the AWS post-vanilla vector', () {
    final auth = vector.authorization(
      method: 'POST',
      url: Uri.parse('https://example.amazonaws.com/'),
      headers: <String, String>{
        'host': 'example.amazonaws.com',
        'x-amz-date': '20150830T123600Z',
      },
      payloadHash: emptyPayloadHash,
    );

    expect(
      auth,
      'AWS4-HMAC-SHA256 '
      'Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, '
      'SignedHeaders=host;x-amz-date, '
      'Signature=5da7c1a2acd57cee7505fc6676e4e544621c30862966e37dddb68e92efbe5d6b',
    );
  });

  test('sign adds host, date, and content-sha256 and signs them in order', () {
    final s3 = NeonS3Signer(
      region: 'us-east-2',
      accessKeyId: 'token-id',
      secretAccessKey: 's3-secret',
      clock: FixedClock(DateTime.utc(2024, 1, 2, 3, 4, 5)),
    );

    final headers = s3.sign(
      method: 'GET',
      url: Uri.parse('https://bucket.storage.neon.tech/files/a.txt'),
    );

    expect(headers['x-amz-date'], '20240102T030405Z');
    expect(headers['x-amz-content-sha256'], emptyPayloadHash);
    expect(headers['host'], 'bucket.storage.neon.tech');
    expect(
      headers['Authorization'],
      contains('SignedHeaders=host;x-amz-content-sha256;x-amz-date'),
    );
    expect(
      headers['Authorization'],
      contains('Credential=token-id/20240102/us-east-2/s3/aws4_request'),
    );
  });

  test('the payload hash covers the request body', () {
    final s3 = NeonS3Signer(
      region: 'us-east-2',
      accessKeyId: 'token-id',
      secretAccessKey: 's3-secret',
      clock: FixedClock(DateTime.utc(2024, 1, 2, 3, 4, 5)),
    );

    final empty = s3.sign(method: 'PUT', url: Uri.parse('https://h/b/k'));
    final filled = s3.sign(
      method: 'PUT',
      url: Uri.parse('https://h/b/k'),
      payload: <int>[104, 101, 108, 108, 111], // "hello"
    );

    // sha256("hello")
    expect(
      filled['x-amz-content-sha256'],
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
    expect(filled['x-amz-content-sha256'], isNot(empty['x-amz-content-sha256']));
  });

  test('presign attaches the SigV4 query parameters and a signature', () {
    final s3 = NeonS3Signer(
      region: 'us-east-2',
      accessKeyId: 'token-id',
      secretAccessKey: 's3-secret',
      clock: FixedClock(DateTime.utc(2024, 1, 2, 3, 4, 5)),
    );

    final url = s3.presign(
      url: Uri.parse('https://h.storage.neon.tech/files/avatars/my%20photo.png'),
      expires: const Duration(minutes: 10),
    );

    expect(url.path, '/files/avatars/my%20photo.png');
    expect(url.queryParameters['X-Amz-Algorithm'], 'AWS4-HMAC-SHA256');
    expect(url.queryParameters['X-Amz-Expires'], '600');
    expect(url.queryParameters['X-Amz-SignedHeaders'], 'host');
    expect(
      url.queryParameters['X-Amz-Credential'],
      'token-id/20240102/us-east-2/s3/aws4_request',
    );
    expect(url.queryParameters['X-Amz-Signature'], isNotNull);
    // The signature must be over the URL as it is actually served.
    expect(url.toString(), contains('X-Amz-Signature='));
  });
}
