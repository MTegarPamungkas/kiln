import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_config.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_support.dart';

void main() {
  test('reports supported for a complete configuration', () {
    final support = AppwriteSupport(
      config: const AppwriteConfig(
        endpoint: 'https://appwrite.test/v1',
        projectId: 'project',
        databaseId: 'database',
        bucketId: 'bucket',
      ),
    );

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['endpoint'], 'https://appwrite.test');
    expect(info.details['database'], 'database');
    expect(info.details['insecure_http'], isFalse);
  });

  test('flags a cleartext endpoint in the details', () {
    final support = AppwriteSupport(
      config: const AppwriteConfig(
        endpoint: 'http://10.0.2.2/v1',
        projectId: 'project',
        databaseId: 'database',
        bucketId: 'bucket',
      ),
    );

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['insecure_http'], isTrue);
  });

  test('reports invalid endpoints as not configured', () {
    final support = AppwriteSupport(
      config: const AppwriteConfig(
        endpoint: 'not-a-url',
        projectId: 'project',
        databaseId: 'database',
        bucketId: 'bucket',
      ),
    );

    final info = support.info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationInvalid);
  });

  test('reports missing identifiers as not configured', () {
    final support = AppwriteSupport(
      config: const AppwriteConfig(
        endpoint: 'https://appwrite.test/v1',
        projectId: '',
        databaseId: 'database',
        bucketId: 'bucket',
      ),
    );

    expect(support.info.state, SupportState.notConfigured);
    expect(support.info.toFailure().code, FailureCode.configurationMissing);
  });
}
