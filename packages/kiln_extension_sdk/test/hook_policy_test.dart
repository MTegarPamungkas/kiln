import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('HookPolicy', () {
    const policy = HookPolicy();

    test('allows official and verified extensions', () {
      expect(policy.canRun(manifestFixtureByName('dio')), isTrue);
      expect(
        policy.canRun(
          makeExtension(id: 'verified', category: 'tooling').manifest,
        ),
        isFalse,
      );
    });

    test('denies community hooks unless the user approves', () {
      final manifest = ExtensionManifest(
        id: 'community',
        name: 'Community',
        version: '1.0.0',
        description: 'Community extension',
        category: 'tooling',
        tier: ExtensionTier.community,
      );

      expect(policy.canRun(manifest), isFalse);
      expect(policy.canRun(manifest, userApproved: true), isTrue);
      expect(
        () => policy.ensureCanRun(manifest),
        throwsA(
          isA<KilnException>().having(
            (error) => error.code,
            'code',
            'hooks.untrusted',
          ),
        ),
      );
    });
  });
}
