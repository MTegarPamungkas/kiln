import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = AppwriteConfig.defaults;

    expect(config.endpoint, 'https://cloud.appwrite.io/v1');
    expect(config.projectId, 'kiln_demo');
    expect(config.databaseId, 'kiln');
    expect(config.bucketId, 'kiln_files');
    expect(
      config.endpointUri.host,
      Uri.parse('https://cloud.appwrite.io/v1').host,
    );
  });

  test('an incomplete configuration fails before the client is built', () {
    const config = AppwriteConfig(projectId: '');

    expect(
      () => config.validate(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.configurationMissing,
        ),
      ),
    );
  });

  test('a relative endpoint is rejected', () {
    const config = AppwriteConfig(endpoint: 'cloud.appwrite.io/v1');

    expect(
      () => config.validate(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.configurationInvalid,
        ),
      ),
    );
  });

  test('flags cleartext http endpoints as insecure', () {
    expect(
      const AppwriteConfig(endpoint: 'https://appwrite.test/v1')
          .isInsecureTransport,
      isFalse,
    );
    expect(
      const AppwriteConfig(endpoint: 'http://10.0.2.2/v1').isInsecureTransport,
      isTrue,
    );
  });
}
