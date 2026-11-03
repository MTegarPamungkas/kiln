import '../kiln_exception.dart';
import '../manifest/extension_manifest.dart';

/// Hooks run on the user's machine, so only trusted tiers may execute them.
final class HookPolicy {
  const HookPolicy({
    this.allowedTiers = const <ExtensionTier>{
      ExtensionTier.official,
      ExtensionTier.verified,
    },
  });

  final Set<ExtensionTier> allowedTiers;

  bool canRun(ExtensionManifest manifest, {bool userApproved = false}) {
    return userApproved || allowedTiers.contains(manifest.tier);
  }

  void ensureCanRun(ExtensionManifest manifest, {bool userApproved = false}) {
    if (canRun(manifest, userApproved: userApproved)) {
      return;
    }
    throw KilnException(
      'Extension "${manifest.id}" wants to run hooks from tier '
      '"${manifest.tier.name}"',
      code: 'hooks.untrusted',
      suggestion: 'Use --yes to approve hooks explicitly, or install a verified extension',
      details: {'extension': manifest.id, 'tier': manifest.tier.name},
    );
  }
}
