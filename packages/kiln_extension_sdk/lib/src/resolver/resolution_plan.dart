import '../manifest/contribution.dart';
import '../manifest/extension_manifest.dart';

/// A manual step that belongs to one extension in the plan.
final class PlannedManualStep {
  const PlannedManualStep({required this.extensionId, required this.step});

  final String extensionId;
  final ManualStep step;
}

/// A slot contribution and whether its `when` conditions are satisfied.
final class ResolvedContribution {
  const ResolvedContribution({
    required this.extension,
    required this.contribution,
    required this.active,
  });

  final AvailableExtension extension;
  final Contribution contribution;
  final bool active;
}

/// The complete result of resolving a requested extension set.
final class ResolutionPlan {
  const ResolutionPlan({
    required this.extensions,
    required this.requested,
    required this.installed,
    required this.capabilities,
    required this.contributions,
    required this.manualSteps,
    this.warnings = const <String>[],
  });

  /// Final install order: dependencies come before dependents.
  final List<AvailableExtension> extensions;
  final Set<String> requested;
  final Set<String> installed;
  final Set<String> capabilities;
  final List<ResolvedContribution> contributions;
  final List<PlannedManualStep> manualSteps;
  final List<String> warnings;

  List<AvailableExtension> get added => <AvailableExtension>[
    for (final extension in extensions)
      if (!installed.contains(extension.id)) extension,
  ];

  List<AvailableExtension> get alreadyInstalled => <AvailableExtension>[
    for (final extension in extensions)
      if (installed.contains(extension.id)) extension,
  ];

  List<ResolvedContribution> get activeContributions => <ResolvedContribution>[
    for (final contribution in contributions)
      if (contribution.active) contribution,
  ];

  Set<String> get extensionIds =>
      extensions.map((extension) => extension.id).toSet();
}
