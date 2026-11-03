import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  const resolver = VersionResolver();

  group('VersionResolver', () {
    test('picks the highest version compatible with kiln', () {
      final extension = _extension([
        _version('1.0.0', kiln: '>=0.1.0 <0.3.0'),
        _version('1.1.0', kiln: '>=0.1.0 <0.3.0'),
        _version('2.0.0', kiln: '>=0.3.0'),
      ]);

      final resolved = resolver.resolve(
        extension,
        kilnVersion: Version.parse('0.2.0'),
      );

      expect(resolved?.version, '1.1.0');
    });

    test('accepts versions without a kiln constraint', () {
      final extension = _extension([
        _version('1.0.0'),
        _version('1.1.0', kiln: '>=0.1.0 <0.3.0'),
      ]);

      expect(
        resolver
            .resolve(extension, kilnVersion: Version.parse('0.2.0'))
            ?.version,
        '1.1.0',
      );
    });

    test('checks the dart constraint only when a dart version is supplied', () {
      final extension = _extension([
        _version('1.0.0', kiln: '>=0.1.0', dart: '>=3.0.0 <4.0.0'),
      ]);

      expect(
        resolver
            .resolve(extension, kilnVersion: Version.parse('0.2.0'))
            ?.version,
        '1.0.0',
      );
      expect(
        resolver.resolve(
          extension,
          kilnVersion: Version.parse('0.2.0'),
          dartVersion: Version.parse('3.5.0'),
        ),
        isNotNull,
      );
      expect(
        resolver.resolve(
          extension,
          kilnVersion: Version.parse('0.2.0'),
          dartVersion: Version.parse('2.19.0'),
        ),
        isNull,
      );
    });

    test('excludes versions at or below the installed version', () {
      final extension = _extension([
        _version('1.0.0', kiln: '>=0.1.0'),
        _version('1.1.0', kiln: '>=0.1.0'),
        _version('1.2.0', kiln: '>=0.1.0'),
      ]);

      expect(
        resolver
            .resolve(
              extension,
              kilnVersion: Version.parse('0.2.0'),
              installedVersion: '1.1.0',
            )
            ?.version,
        '1.2.0',
      );
      expect(
        resolver.resolve(
          extension,
          kilnVersion: Version.parse('0.2.0'),
          installedVersion: '1.2.0',
        ),
        isNull,
      );
    });

    test('skips prereleases unless allowed', () {
      final extension = _extension([
        _version('1.0.0', kiln: '>=0.1.0'),
        _version('1.1.0-beta.1', kiln: '>=0.1.0'),
      ]);

      expect(
        resolver
            .resolve(extension, kilnVersion: Version.parse('0.2.0'))
            ?.version,
        '1.0.0',
      );
      expect(
        resolver
            .resolve(
              extension,
              kilnVersion: Version.parse('0.2.0'),
              allowPrerelease: true,
            )
            ?.version,
        '1.1.0-beta.1',
      );
    });

    test('skips malformed versions and constraints', () {
      final extension = _extension([
        _version('not-semver', kiln: '>=0.1.0'),
        _version('1.0.0', kiln: 'this is not a range'),
        _version('1.1.0', kiln: '>=0.1.0'),
      ]);

      expect(
        resolver
            .resolve(extension, kilnVersion: Version.parse('0.2.0'))
            ?.version,
        '1.1.0',
      );
    });

    test('returns null when nothing is compatible', () {
      final extension = _extension([_version('1.0.0', kiln: '>=1.0.0')]);

      expect(
        resolver.resolve(extension, kilnVersion: Version.parse('0.2.0')),
        isNull,
      );
      expect(
        resolver.resolve(_extension([]), kilnVersion: Version.parse('0.2.0')),
        isNull,
      );
    });
  });
}

RegistryVersion _version(String version, {String? kiln, String? dart}) {
  return RegistryVersion(
    version: version,
    url: 'archives/demo-$version.tgz',
    sha256: '0' * 64,
    compatibility: <String, String>{'kiln': ?kiln, 'dart': ?dart},
  );
}

RegistryExtension _extension(List<RegistryVersion> versions) {
  return RegistryExtension(
    id: 'demo',
    name: 'Demo',
    description: 'Demo extension',
    category: 'testing',
    latest: versions.isEmpty ? '0.0.0' : versions.last.version,
    tier: ExtensionTier.community,
    versions: versions,
  );
}
