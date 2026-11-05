import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final fixtureFile = File(
    p.join(
      Directory.current.path,
      'test',
      'fixtures',
      'registry',
      'index.json',
    ),
  );

  late RegistryIndex fixture;

  setUp(() {
    fixture = RegistryIndex.parse(fixtureFile.readAsStringSync());
  });

  group('SearchIndex', () {
    test('an empty query returns every extension', () {
      final results = SearchIndex(fixture).search('');

      expect(results.map((extension) => extension.id), [
        'demo_ext',
        'http_retry',
      ]);
    });

    test('matches id, name, description, and category case-insensitively', () {
      final index = SearchIndex(fixture);

      expect(index.search('DEMO').map((extension) => extension.id), [
        'demo_ext',
      ]);
      expect(index.search('retry').map((extension) => extension.id), [
        'http_retry',
      ]);
      expect(index.search('backoff').map((extension) => extension.id), [
        'http_retry',
      ]);
      expect(index.search('network').map((extension) => extension.id), [
        'http_retry',
      ]);
      expect(index.search('testing').map((extension) => extension.id), [
        'demo_ext',
      ]);
    });

    test('returns an empty list when nothing matches', () {
      expect(SearchIndex(fixture).search('database'), isEmpty);
    });

    test('ranks exact id matches before substring matches', () {
      final index = RegistryIndex(
        generatedAt: DateTime.utc(2026),
        extensions: [
          _extension('http_retry', 'HTTP Retry'),
          _extension('http', 'HTTP'),
          _extension('http_extra', 'HTTP Extra'),
        ],
      );

      expect(SearchIndex(index).search('http').map((item) => item.id), [
        'http',
        'http_extra',
        'http_retry',
      ]);
    });

    test('delegates to RegistryIndex.search', () {
      expect(
        SearchIndex(fixture).search('demo').map((extension) => extension.id),
        fixture.search('demo').map((extension) => extension.id),
      );
    });
  });
}

RegistryExtension _extension(String id, String name) {
  return RegistryExtension(
    id: id,
    name: name,
    description: '$name description',
    category: 'network',
    latest: '1.0.0',
    tier: ExtensionTier.community,
    versions: [
      RegistryVersion(version: '1.0.0', url: '$id-1.0.0.tgz', sha256: '0' * 64),
    ],
  );
}
