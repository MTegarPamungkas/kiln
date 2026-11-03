import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

/// The outcome of applying a [TrustPolicy] to a manifest.
final class TrustDecision {
  const TrustDecision({
    required this.allowed,
    required this.requiresConfirmation,
    required this.reason,
  });

  /// Whether installation may proceed at all.
  final bool allowed;

  /// Whether the user must explicitly confirm before hooks or community code
  /// run.
  final bool requiresConfirmation;

  /// Human-readable explanation shown to the user.
  final String reason;

  Map<String, Object?> toJson() => <String, Object?>{
    'allowed': allowed,
    'requires_confirmation': requiresConfirmation,
    'reason': reason,
  };
}

/// Decides which extension tiers may run and when confirmation is required.
final class TrustPolicy {
  const TrustPolicy({
    this.allowed = _allTiers,
    this.confirmCommunity = true,
    this.confirmHooks = true,
  });

  static const Set<ExtensionTier> _allTiers = <ExtensionTier>{
    ExtensionTier.official,
    ExtensionTier.verified,
    ExtensionTier.community,
  };

  /// Tiers that may be installed. Official extensions are always allowed.
  final Set<ExtensionTier> allowed;

  /// Whether community extensions need explicit confirmation.
  final bool confirmCommunity;

  /// Whether any extension with hooks needs explicit confirmation.
  final bool confirmHooks;

  /// Evaluates [manifest], optionally told whether the bundle contains hooks.
  TrustDecision evaluate(ExtensionManifest manifest, {bool hasHooks = false}) {
    final tier = manifest.tier;
    final isAllowed = tier == ExtensionTier.official || allowed.contains(tier);
    if (!isAllowed) {
      return TrustDecision(
        allowed: false,
        requiresConfirmation: false,
        reason:
            'Extension "${manifest.id}" is ${tier.name} tier and that tier '
            'is not allowed by the current trust policy.',
      );
    }

    final reasons = <String>[
      if (tier == ExtensionTier.community && confirmCommunity)
        'Community extensions are not reviewed by Kiln',
      if (hasHooks && confirmHooks) 'This extension runs hooks during install',
    ];
    if (reasons.isNotEmpty) {
      return TrustDecision(
        allowed: true,
        requiresConfirmation: true,
        reason: '${reasons.join('; ')}.',
      );
    }
    return TrustDecision(
      allowed: true,
      requiresConfirmation: false,
      reason: 'Extension "${manifest.id}" is ${tier.name} tier and is trusted.',
    );
  }
}
