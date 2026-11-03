import '../manifest/extension_manifest.dart';
import 'capability_index.dart';
import 'conflict_report.dart';
import 'resolution_plan.dart';

/// Resolves requested extension ids and their capability requirements.
///
/// Extensions depend on capabilities, never on extension ids. If more than one
/// extension provides the same capability, resolution fails instead of
/// guessing.
final class ExtensionResolver {
  const ExtensionResolver(this.available);

  final List<AvailableExtension> available;

  ResolutionPlan resolve({
    required Set<String> installed,
    required Set<String> requested,
    Set<String> hostCapabilities = const <String>{},
    Set<String> hostSlots = const <String>{'app.wrappers'},
  }) {
    final index = CapabilityIndex(available);
    final conflicts = <ResolutionConflict>[];
    final warnings = <String>[];
    final selected = <String, AvailableExtension>{};

    for (final id in <String>{...installed, ...requested}) {
      final extension = index.byId(id);
      if (extension == null) {
        conflicts.add(
          ResolutionConflict(
            kind: ConflictKind.unknownExtension,
            message: 'Extension "$id" is not available in the catalog',
            suggestion: 'Run "kiln list --available" to see known extensions',
            extensionIds: <String>[id],
          ),
        );
        continue;
      }
      selected[id] = extension;
    }

    final queue = selected.values.toList(growable: true);
    final visitedRequirements = <String>{};
    while (queue.isNotEmpty) {
      final extension = queue.removeAt(0);
      for (final capability in extension.manifest.requires) {
        if (hostCapabilities.contains(capability)) {
          continue;
        }
        final providers = index.providersOf(capability);
        if (providers.isEmpty) {
          conflicts.add(
            ResolutionConflict(
              kind: ConflictKind.missingCapability,
              message:
                  'Extension "${extension.id}" requires "$capability" but nothing provides it',
              suggestion: 'Add an extension that provides "$capability"',
              extensionIds: <String>[extension.id],
            ),
          );
          continue;
        }

        final alreadySelected = providers.where(
          (provider) => selected.containsKey(provider.id),
        );
        if (alreadySelected.isNotEmpty) {
          continue;
        }

        if (providers.length > 1) {
          conflicts.add(
            ResolutionConflict(
              kind: ConflictKind.duplicateCapability,
              message:
                  'Capability "$capability" is provided by more than one extension: '
                  '${providers.map((provider) => provider.id).join(', ')}',
              suggestion: 'Install only one provider, or make one of them provide a distinct capability',
              extensionIds: providers
                  .map((provider) => provider.id)
                  .toList(growable: false),
            ),
          );
          continue;
        }

        final provider = providers.single;
        selected[provider.id] = provider;
        if (visitedRequirements.add('${extension.id}:$capability')) {
          queue.add(provider);
        }
      }
    }

    _checkExclusiveCategories(selected, conflicts);
    final openedSlots = <String, String>{
      for (final extension in selected.values)
        for (final slot in extension.manifest.slots) slot.name: slot.item,
      ...<String, String>{for (final slot in hostSlots) slot: 'host'},
    };
    final contributions = <ResolvedContribution>[];
    final capabilities = <String>{
      ...hostCapabilities,
      for (final extension in selected.values) ...extension.manifest.provides,
    };

    for (final extension in selected.values) {
      for (final contribution in extension.manifest.contributions) {
        final slotItem = openedSlots[contribution.slot];
        if (slotItem == null) {
          conflicts.add(
            ResolutionConflict(
              kind: ConflictKind.slotNotOpened,
              message:
                  'Extension "${extension.id}" contributes to "${contribution.slot}" but no selected extension opens it',
              suggestion:
                  'Install the extension that opens "${contribution.slot}"',
              extensionIds: <String>[extension.id],
            ),
          );
          contributions.add(
            ResolvedContribution(
              extension: extension,
              contribution: contribution,
              active: false,
            ),
          );
          continue;
        }
        if (contribution.item != null &&
            slotItem != 'host' &&
            slotItem != contribution.item) {
          conflicts.add(
            ResolutionConflict(
              kind: ConflictKind.slotItemTypeMismatch,
              message:
                  'Extension "${extension.id}" contributes "${contribution.item}" to '
                  '"${contribution.slot}", which expects "$slotItem"',
              suggestion: 'Use the item type declared by the slot opener',
              extensionIds: <String>[extension.id],
            ),
          );
        }
        final active = contribution.isActive(capabilities);
        if (!active && contribution.when.isNotEmpty) {
          warnings.add(
            'Contribution "${extension.id}" to "${contribution.slot}" is inactive: '
            'missing ${contribution.when.where((cap) => !capabilities.contains(cap)).join(', ')}',
          );
        }
        contributions.add(
          ResolvedContribution(
            extension: extension,
            contribution: contribution,
            active: active,
          ),
        );
      }
    }

    final ordered = _orderExtensions(
      selected,
      index,
      hostCapabilities,
      conflicts,
    );

    if (conflicts.isNotEmpty) {
      throw ResolutionException(conflicts);
    }

    for (final id in requested) {
      if (installed.contains(id)) {
        warnings.add('Extension "$id" is already installed');
      }
    }

    final manualSteps = <PlannedManualStep>[
      for (final extension in ordered)
        if (!installed.contains(extension.id))
          for (final step in extension.manifest.manualSteps)
            PlannedManualStep(extensionId: extension.id, step: step),
    ];

    return ResolutionPlan(
      extensions: List<AvailableExtension>.unmodifiable(ordered),
      requested: Set<String>.unmodifiable(requested),
      installed: Set<String>.unmodifiable(installed),
      capabilities: Set<String>.unmodifiable(capabilities),
      contributions: List<ResolvedContribution>.unmodifiable(contributions),
      manualSteps: List<PlannedManualStep>.unmodifiable(manualSteps),
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  void _checkExclusiveCategories(
    Map<String, AvailableExtension> selected,
    List<ResolutionConflict> conflicts,
  ) {
    final byCategory = <String, List<AvailableExtension>>{};
    for (final extension in selected.values) {
      if (extension.manifest.exclusive) {
        byCategory
            .putIfAbsent(
              extension.manifest.category,
              () => <AvailableExtension>[],
            )
            .add(extension);
      }
    }
    for (final entry in byCategory.entries) {
      if (entry.value.length < 2) {
        continue;
      }
      conflicts.add(
        ResolutionConflict(
          kind: ConflictKind.exclusiveCategory,
          message:
              'Category "${entry.key}" is exclusive but these extensions are selected: '
              '${entry.value.map((extension) => extension.id).join(', ')}',
          suggestion: 'Remove one of the extensions in that category',
          extensionIds: entry.value
              .map((extension) => extension.id)
              .toList(growable: false),
        ),
      );
    }
  }

  List<AvailableExtension> _orderExtensions(
    Map<String, AvailableExtension> selected,
    CapabilityIndex index,
    Set<String> hostCapabilities,
    List<ResolutionConflict> conflicts,
  ) {
    final ordered = <AvailableExtension>[];
    final state = <String, int>{};
    final stack = <String>[];

    void visit(AvailableExtension extension) {
      final current = state[extension.id] ?? 0;
      if (current == 2) {
        return;
      }
      if (current == 1) {
        final start = stack.indexOf(extension.id);
        final cycle = <String>[
          ...stack.sublist(start < 0 ? 0 : start),
          extension.id,
        ];
        conflicts.add(
          ResolutionConflict(
            kind: ConflictKind.dependencyCycle,
            message: 'Circular extension dependency: ${cycle.join(' -> ')}',
            suggestion: 'Break the cycle by depending on capabilities instead',
            extensionIds: cycle,
          ),
        );
        return;
      }
      state[extension.id] = 1;
      stack.add(extension.id);
      for (final capability in extension.manifest.requires) {
        if (hostCapabilities.contains(capability)) {
          continue;
        }
        final provider = index.singleProviderOf(capability);
        final selectedProvider = provider == null
            ? null
            : selected[provider.id];
        if (selectedProvider != null) {
          visit(selectedProvider);
        }
      }
      stack.removeLast();
      state[extension.id] = 2;
      if (!ordered.any((item) => item.id == extension.id)) {
        ordered.add(extension);
      }
    }

    for (final extension in selected.values) {
      visit(extension);
    }
    return ordered;
  }
}
