import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_config.dart';

void main() {
  const valid = NeonStorageConfig(
    signingUrl: 'https://signing.example.test/storage/sign',
    bucket: 'files',
  );

  test('a complete configuration is valid', () {
    expect(valid.validate(), isNull);
    expect(valid.signedUrlLifetime, const Duration(minutes: 5));
  });

  test('the signing URL must be HTTPS', () {
    expect(
      valid.copyWith(signingUrl: 'http://signing.example.test/sign').validate()?.code,
      FailureCode.configurationInvalid,
    );
    expect(
      valid.copyWith(signingUrl: 'http://localhost:8080/sign').validate(),
      isNull,
    );
  });

  test('credentials, query, and fragment in the signing URL are rejected', () {
    for (final url in <String>[
      'https://user:pass@signing.example.test/sign',
      'https://signing.example.test/sign?secret=1',
      'https://signing.example.test/sign#fragment',
      'signing.example.test/sign',
      'neon://signing.example.test/sign',
    ]) {
      expect(
        valid.copyWith(signingUrl: url).validate()?.code,
        FailureCode.configurationInvalid,
        reason: url,
      );
    }
  });

  test('an invalid bucket name is rejected', () {
    expect(
      valid.copyWith(bucket: 'Bad_Bucket').validate()?.code,
      FailureCode.configurationInvalid,
    );
  });

  test('lifetimes must be whole seconds within fifteen minutes', () {
    for (final duration in <Duration>[
      Duration.zero,
      const Duration(milliseconds: 500),
      const Duration(seconds: 901),
      const Duration(minutes: 15, milliseconds: 1),
    ]) {
      expect(
        valid.copyWith(signedUrlLifetime: duration).validate()?.code,
        FailureCode.configurationInvalid,
        reason: '$duration',
      );
    }
    expect(
      valid.copyWith(signedUrlLifetime: const Duration(minutes: 15)).validate(),
      isNull,
    );
  });

  test('the configuration never contains an S3 credential', () {
    final map = valid.copyWith(bucket: 'files').validate();
    expect(map, isNull);
    expect(valid.toString(), isNot(contains('secret')));
  });
}
