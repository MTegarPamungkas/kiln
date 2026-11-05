import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_config.dart';

void main() {
  const valid = NeonConfig(
    dataApiUrl: 'https://demo.aws.neon.tech/sql/rest',
    apiKey: 'token',
    schema: 'public',
  );

  test('a complete configuration is valid', () {
    expect(valid.validate(), isNull);
    expect(valid.watchInterval, const Duration(seconds: 5));
  });

  test('an insecure transport is detected from the URL', () {
    expect(valid.isInsecureTransport, isFalse);
    expect(
      valid.copyWith(dataApiUrl: 'http://localhost:54321/rest')
          .isInsecureTransport,
      isTrue,
    );
  });

  test('a non-http URL is rejected', () {
    final failure = valid.copyWith(dataApiUrl: 'neon://host').validate();

    expect(failure?.code, FailureCode.configurationInvalid);
  });

  test('a blank token is reported as missing', () {
    final failure = valid.copyWith(apiKey: '   ').validate();

    expect(failure?.code, FailureCode.configurationMissing);
  });

  test('the bearer token value is never echoed in a failure message', () {
    final failure = valid
        .copyWith(
          apiKey: 'super-secret-value',
          schema: '1bad',
        )
        .validate();

    expect(failure?.code, FailureCode.configurationInvalid);
    expect(failure?.message, isNot(contains('super-secret-value')));
  });

  test('an invalid schema is rejected', () {
    final failure = valid.copyWith(schema: '1public').validate();

    expect(failure?.code, FailureCode.configurationInvalid);
  });

  test('a non-positive watch interval is rejected', () {
    final failure = valid
        .copyWith(watchInterval: Duration.zero)
        .validate();

    expect(failure?.code, FailureCode.configurationInvalid);
  });

  test('copyWith keeps unchanged fields', () {
    final updated = valid.copyWith(schema: 'app');

    expect(updated.schema, 'app');
    expect(updated.dataApiUrl, valid.dataApiUrl);
    expect(updated.apiKey, valid.apiKey);
    expect(updated.watchInterval, valid.watchInterval);
  });
}
