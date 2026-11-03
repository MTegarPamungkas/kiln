import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:test/test.dart';

void main() {
  group('TrustPolicy', () {
    test('always allows official extensions without confirmation', () {
      final decision = const TrustPolicy().evaluate(
        _manifest(ExtensionTier.official),
      );

      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isFalse);
      expect(decision.reason, contains('official'));
    });

    test('allows verified extensions without confirmation', () {
      final decision = const TrustPolicy().evaluate(
        _manifest(ExtensionTier.verified),
      );

      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isFalse);
    });

    test('allows community only with confirmation by default', () {
      final decision = const TrustPolicy().evaluate(
        _manifest(ExtensionTier.community),
      );

      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isTrue);
      expect(decision.reason, contains('Community'));
    });

    test('rejects tiers that the policy does not allow', () {
      final decision = const TrustPolicy(
        allowed: <ExtensionTier>{ExtensionTier.official},
      ).evaluate(_manifest(ExtensionTier.verified));

      expect(decision.allowed, isFalse);
      expect(decision.requiresConfirmation, isFalse);
      expect(decision.reason, contains('verified'));
    });

    test('official is allowed even when it is not in the allowed set', () {
      final decision = const TrustPolicy(
        allowed: <ExtensionTier>{ExtensionTier.verified},
      ).evaluate(_manifest(ExtensionTier.official));

      expect(decision.allowed, isTrue);
    });

    test('hooks require confirmation for trusted tiers', () {
      final decision = const TrustPolicy().evaluate(
        _manifest(ExtensionTier.verified),
        hasHooks: true,
      );

      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isTrue);
      expect(decision.reason, contains('hooks'));
    });

    test('hooks still require confirmation for official extensions', () {
      final decision = const TrustPolicy().evaluate(
        _manifest(ExtensionTier.official),
        hasHooks: true,
      );

      expect(decision.allowed, isTrue);
      expect(decision.requiresConfirmation, isTrue);
    });

    test('confirmation flags can be disabled', () {
      final policy = const TrustPolicy(
        confirmCommunity: false,
        confirmHooks: false,
      );

      final community = policy.evaluate(_manifest(ExtensionTier.community));
      final hooks = policy.evaluate(
        _manifest(ExtensionTier.verified),
        hasHooks: true,
      );

      expect(community.allowed, isTrue);
      expect(community.requiresConfirmation, isFalse);
      expect(hooks.allowed, isTrue);
      expect(hooks.requiresConfirmation, isFalse);
    });

    test('decision serialises to JSON', () {
      final json = const TrustPolicy()
          .evaluate(_manifest(ExtensionTier.community))
          .toJson();

      expect(json['allowed'], isTrue);
      expect(json['requires_confirmation'], isTrue);
      expect(json['reason'], isA<String>());
    });
  });
}

ExtensionManifest _manifest(ExtensionTier tier) {
  return ExtensionManifest(
    id: 'demo_ext',
    name: 'Demo',
    version: '1.0.0',
    description: 'Demo extension',
    category: 'testing',
    tier: tier,
  );
}
