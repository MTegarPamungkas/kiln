import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = AppwriteConfig.defaults;

    expect(config.endpoint, '{{{endpoint}}}');
    expect(config.projectId, '{{{project_id}}}');
    expect(config.databaseId, '{{{database_id}}}');
    expect(config.bucketId, '{{{bucket_id}}}');
    expect(config.endpointUri.host, Uri.parse('{{{endpoint}}}').host);
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
