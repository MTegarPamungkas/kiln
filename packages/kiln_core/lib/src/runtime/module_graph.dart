import 'kiln_module.dart';

/// A problem with module ids, capabilities, or ordering.
final class ModuleGraphException implements Exception {
  const ModuleGraphException(
    this.message, {
    this.moduleId,
    this.capability,
    this.cycle = const <String>[],
  });

  final String message;
  final String? moduleId;
  final String? capability;
  final List<String> cycle;

  @override
  String toString() {
    final suffix = cycle.isEmpty ? '' : ' (cycle: ${cycle.join(' -> ')})';
    return 'ModuleGraphException: $message$suffix';
  }
}

/// Resolves capability dependencies into a stable initialization order.
final class ModuleGraph {
  ModuleGraph(this.modules);

  final List<KilnModule> modules;

  List<KilnModule> resolve({
    Set<String> availableCapabilities = const <String>{},
  }) {
    final providers = _buildProviderIndex();
    _validateRequirements(providers, availableCapabilities);

    final ordered = <KilnModule>[];
    final state = <String, int>{};
    final stack = <String>[];

    void visit(KilnModule module) {
      final current = state[module.id] ?? 0;
      if (current == 2) {
        return;
      }
      if (current == 1) {
        final start = stack.indexOf(module.id);
        final cycle = <String>[
          ...stack.sublist(start < 0 ? 0 : start),
          module.id,
        ];
        throw ModuleGraphException(
          'Circular module dependency',
          moduleId: module.id,
          cycle: cycle,
        );
      }
      state[module.id] = 1;
      stack.add(module.id);
      for (final capability in module.requires) {
        final provider = providers[capability];
        if (provider != null) {
          visit(provider);
        }
      }
      for (final capability in module.optionalRequires) {
        final provider = providers[capability];
        // Optional edges only order modules; a provider already on the stack
        // would turn an optional preference into a dependency cycle.
        if (provider != null && state[provider.id] != 1) {
          visit(provider);
        }
      }
      stack.removeLast();
      state[module.id] = 2;
      ordered.add(module);
    }

    for (final module in modules) {
      visit(module);
    }
    return List<KilnModule>.unmodifiable(ordered);
  }

  Map<String, KilnModule> _buildProviderIndex() {
    final providers = <String, KilnModule>{};
    final ids = <String>{};
    for (final module in modules) {
      if (!ids.add(module.id)) {
        throw ModuleGraphException('Duplicate module id', moduleId: module.id);
      }
      for (final capability in module.provides) {
        final existing = providers[capability];
        if (existing != null) {
          throw ModuleGraphException(
            'Capability provided by more than one module',
            moduleId: module.id,
            capability: capability,
          );
        }
        providers[capability] = module;
      }
    }
    return providers;
  }

  void _validateRequirements(
    Map<String, KilnModule> providers,
    Set<String> availableCapabilities,
  ) {
    for (final module in modules) {
      for (final capability in module.requires) {
        if (!providers.containsKey(capability) &&
            !availableCapabilities.contains(capability)) {
          throw ModuleGraphException(
            'Missing capability required by module',
            moduleId: module.id,
            capability: capability,
          );
        }
      }
    }
  }
}
