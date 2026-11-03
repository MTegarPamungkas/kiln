import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('UpgradePlanner', () {
    test('plans an upgrade when a newer version is available', () {
      final planner = UpgradePlanner(
        available: [makeExtension(id: 'dio', version: '1.1.0')],
      );

      final candidates = planner.plan(
        installedVersions: const {'dio': '1.0.0'},
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.id, 'dio');
      expect(candidates.single.from, '1.0.0');
      expect(candidates.single.to, '1.1.0');
    });

    test('ignores same or older versions and unknown extensions', () {
      final planner = UpgradePlanner(
        available: [
          makeExtension(id: 'dio', version: '1.0.0'),
          makeExtension(id: 'other', version: '1.0.0'),
        ],
      );

      expect(
        planner.plan(
          installedVersions: const {
            'dio': '1.0.0',
            'other': '2.0.0',
            'missing': '1.0.0',
          },
        ),
        isEmpty,
      );
    });

    test('can filter to one extension', () {
      final planner = UpgradePlanner(
        available: [
          makeExtension(id: 'a', version: '2.0.0'),
          makeExtension(id: 'b', version: '2.0.0'),
        ],
      );

      final candidates = planner.plan(
        installedVersions: const {'a': '1.0.0', 'b': '1.0.0'},
        only: const {'b'},
        all: false,
      );

      expect(candidates.map((candidate) => candidate.id), ['b']);
    });

    test('skips malformed installed versions', () {
      final planner = UpgradePlanner(
        available: [makeExtension(id: 'dio', version: '1.0.0')],
      );

      expect(
        planner.plan(installedVersions: const {'dio': 'not-semver'}),
        isEmpty,
      );
    });
  });
}
