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
      containsAll(<String>['auth', 'remote_database', 'file_storage']),
    );
    expect(manifest.optionalRequires, isEmpty);
    expect(manifest.dependencies, containsPair('http', '^1.6.0'));
    expect(manifest.dependencies.containsKey('crypto'), isFalse);
    expect(manifest.platformSetup.android.permissions, <String>[
      'android.permission.INTERNET',
    ]);
    expect(manifest.manualSteps, hasLength(4));

    final url = manifest.promptsByName['data_api_url'];
    expect(url, isNotNull);
    expect(url!.type.name, 'url');
    expect(url.required, isTrue);

    final apiKey = manifest.promptsByName['api_key'];
    expect(apiKey, isNotNull);
    expect(apiKey!.type.name, 'secret');
    expect(apiKey.secret, isTrue);
    expect(apiKey.required, isFalse);

    final authUrl = manifest.promptsByName['auth_url'];
    expect(authUrl, isNotNull);
    expect(authUrl!.type.name, 'string');
    expect(authUrl.required, isFalse);

    final signingUrl = manifest.promptsByName['storage_signing_url'];
    expect(signingUrl, isNotNull);
    expect(signingUrl!.type.name, 'url');
    expect(signingUrl.required, isTrue);

    final bucket = manifest.promptsByName['s3_bucket'];
    expect(bucket, isNotNull);
    expect(bucket!.type.name, 'string');
    expect(bucket.defaultValue, 'files');

    for (final removed in <String>[
      's3_endpoint',
      's3_region',
      's3_access_key_id',
      's3_secret_access_key',
    ]) {
      expect(manifest.promptsByName[removed], isNull, reason: removed);
    }

    expect(manifest.compatibility.kiln, '>=0.1.0 <0.2.0');
    expect(manifest.compatibility.dart, '>=3.9.0');
  });
}
