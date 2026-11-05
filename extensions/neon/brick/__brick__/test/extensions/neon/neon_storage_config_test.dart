import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_config.dart';

void main() {
  const valid = NeonStorageConfig(
    endpoint: 'https://demo.storage.c-us-east-2.aws.neon.tech',
    bucket: 'files',
    region: 'us-east-2',
    accessKeyId: 'token-id',
    secretAccessKey: 's3-secret',
  );

  test('a complete configuration is valid', () {
    expect(valid.validate(), isNull);
    expect(valid.signedUrlLifetime, const Duration(hours: 1));
  });

  test('object URLs use path-style addressing', () {
    final uri = valid.objectUri('avatars/my photo.png');

    expect(uri.scheme, 'https');
    expect(uri.host, 'demo.storage.c-us-east-2.aws.neon.tech');
    expect(uri.path, '/files/avatars/my%20photo.png');
  });

  test('a trailing slash on the endpoint is not doubled', () {
    final uri = valid.copyWith(endpoint: 'https://h/').objectUri('a.txt');

    expect(uri.path, '/files/a.txt');
  });

  test('insecure transport is detected', () {
    expect(valid.isInsecureTransport, isFalse);
    expect(
      valid.copyWith(endpoint: 'http://localhost:9000').isInsecureTransport,
      isTrue,
    );
  });

  test('a non-http endpoint is rejected', () {
    expect(
      valid.copyWith(endpoint: 'neon://bucket').validate()?.code,
      FailureCode.configurationInvalid,
    );
  });

  test('an invalid bucket name is rejected', () {
    expect(
      valid.copyWith(bucket: 'Bad_Bucket').validate()?.code,
      FailureCode.configurationInvalid,
    );
  });

  test('blank region and keys are reported as missing', () {
    expect(
      valid.copyWith(region: ' ').validate()?.code,
      FailureCode.configurationMissing,
    );
    expect(
      valid.copyWith(accessKeyId: '').validate()?.code,
      FailureCode.configurationMissing,
    );
    expect(
      valid.copyWith(secretAccessKey: '').validate()?.code,
      FailureCode.configurationMissing,
    );
  });

  test('the secret is never echoed in a failure message', () {
    final failure = valid
        .copyWith(
          secretAccessKey: 'super-secret-value',
          region: '',
        )
        .validate();

    expect(failure?.code, FailureCode.configurationMissing);
    expect(failure?.message, isNot(contains('super-secret-value')));
  });

  test('a non-positive signed URL lifetime is rejected', () {
    expect(
      valid.copyWith(signedUrlLifetime: Duration.zero).validate()?.code,
      FailureCode.configurationInvalid,
    );
  });
}
