import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final fixtures = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'registry'),
  );

  RegistryIndex loadFixture() {
    return RegistryIndex.parse(
      File(p.join(fixtures.path, 'index.json')).readAsStringSync(),
    );
  }

  group('RegistryIndex', () {
    test('parses generated_at and every extension from the fixture', () {
      final index = loadFixture();

      expect(index.generatedAt.toUtc(), DateTime.utc(2026, 1, 15, 9, 30));
      expect(index.extensions.map((extension) => extension.id), [
        'demo_ext',
        'http_retry',
      ]);
      expect(index.extensions.first.tier, ExtensionTier.verified);
      expect(index.extensions.last.tier, ExtensionTier.official);
      expect(index.extensions.first.latest, '1.2.0');
      expect(index.extensions.first.versions, hasLength(3));
    });

    test(
      'parses version metadata including requires, provides, and ranges',
      () {
        final version = loadFixture().find('demo_ext')!.findVersion('1.1.0')!;

        expect(version.requires, ['app_basic']);
        expect(version.provides, ['demo', 'demo_hooks']);
        expect(version.compatibility['kiln'], '>=0.2.0 <0.4.0');
        expect(
          version.sha256,
          '1111111111111111111111111111111111111111111111111111111111111111',
        );
      },
    );

    test('find returns null for unknown ids and versions', () {
      final index = loadFixture();

      expect(index.find('missing'), isNull);
      expect(index.find('demo_ext')!.findVersion('9.9.9'), isNull);
      expect(index.find('demo_ext')!.findVersion('1.0.0')!.version, '1.0.0');
    });

    test('resolveUrl keeps absolute URLs and resolves relative ones', () {
      final index = loadFixture();
      final extension = index.find('demo_ext')!;
      final indexUri = Uri.parse(
        'https://registry.example.com/kiln/index.json',
      );

      expect(
        extension.findVersion('1.0.0')!.resolveUrl(indexUri).toString(),
        'https://registry.example.com/kiln/valid.tgz',
      );
      expect(
        extension.findVersion('1.1.0')!.resolveUrl(indexUri).toString(),
        'https://registry.example.com/kiln/archives/demo_ext-1.1.0.tgz',
      );
      expect(
        extension.findVersion('1.2.0')!.resolveUrl(indexUri).toString(),
        'https://cdn.example.com/kiln/demo_ext-1.2.0.tgz',
      );
    });

    test('encode is schema compliant and round-trips', () {
      final index = loadFixture();
      final decoded = jsonDecode(index.encode()) as Map<String, Object?>;

      expect(decoded['schema_version'], 1);
      expect(decoded['generated_at'], isA<String>());
      expect(DateTime.parse(decoded['generated_at']! as String).isUtc, isTrue);
      expect(decoded['extensions'], isA<List<Object?>>());

      final reparsed = RegistryIndex.parse(index.encode());
      expect(reparsed.generatedAt, index.generatedAt);
      expect(reparsed.extensions, hasLength(index.extensions.length));
      expect(reparsed.find('demo_ext')!.latest, '1.2.0');
      expect(
        reparsed.find('demo_ext')!.toJson(),
        index.find('demo_ext')!.toJson(),
      );
    });

    test('rejects unsupported schema versions', () {
      expect(
        () => RegistryIndex.parse(
          '{"schema_version": 2, "generated_at": "2026-01-01T00:00:00Z", '
          '"extensions": []}',
        ),
        throwsA(
          isA<KilnStoreException>()
              .having((error) => error.code, 'code', 'store.index_invalid')
              .having((error) => error.message, 'message', contains('schema')),
        ),
      );
    });

    test('rejects malformed JSON and invalid tiers', () {
      expect(
        () => RegistryIndex.parse('not json'),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.index_invalid',
          ),
        ),
      );

      const invalidTier =
          '{"schema_version": 1, "generated_at": "2026-01-01T00:00:00Z", '
          '"extensions": [{"id": "demo", "name": "Demo", "latest": "1.0.0", '
          '"tier": "gold", "versions": []}]}';
      expect(
        () => RegistryIndex.parse(invalidTier),
        throwsA(
          isA<KilnStoreException>()
              .having((error) => error.code, 'code', 'store.index_invalid')
              .having((error) => error.message, 'message', contains('tier')),
        ),
      );
    });

    test('search ranks exact ids and matches description', () {
      final matches = loadFixture().search('demo');
      expect(matches.first.id, 'demo_ext');
      expect(matches, hasLength(1));
      expect(loadFixture().search('backoff').single.id, 'http_retry');
    });
  });
}
