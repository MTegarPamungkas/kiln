import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('neon manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.id, 'neon');
    expect(manifest.category, 'database');
    expect(manifest.exclusive, isFalse);
    expect(
      manifest.provides,
      containsAll(<String>['remote_database', 'file_storage']),
    );
    expect(manifest.optionalRequires, isEmpty);
    expect(manifest.dependencies, containsPair('http', '^1.6.0'));
    expect(manifest.dependencies, containsPair('crypto', '^3.0.8'));
    expect(manifest.platformSetup.android.permissions, <String>[
      'android.permission.INTERNET',
    ]);
    expect(manifest.manualSteps, hasLength(3));

    final url = manifest.promptsByName['data_api_url'];
    expect(url, isNotNull);
    expect(url!.type.name, 'url');
    expect(url.required, isTrue);

    final apiKey = manifest.promptsByName['api_key'];
    expect(apiKey, isNotNull);
    expect(apiKey!.type.name, 'secret');
    expect(apiKey.secret, isTrue);

    final s3Endpoint = manifest.promptsByName['s3_endpoint'];
    expect(s3Endpoint, isNotNull);
    expect(s3Endpoint!.type.name, 'url');
    expect(s3Endpoint.required, isTrue);

    final s3Secret = manifest.promptsByName['s3_secret_access_key'];
    expect(s3Secret, isNotNull);
    expect(s3Secret!.type.name, 'secret');
    expect(s3Secret.secret, isTrue);

    final bucket = manifest.promptsByName['s3_bucket'];
    expect(bucket, isNotNull);
    expect(bucket!.type.name, 'string');
    expect(bucket.defaultValue, 'files');

    final region = manifest.promptsByName['s3_region'];
    expect(region, isNotNull);
    expect(region!.defaultValue, 'us-east-2');

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
