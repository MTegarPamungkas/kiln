import 'package:kiln_core/kiln_core.dart';

import 'flavors_support.dart';
import 'release_guard.dart';

/// Registers the build flavor and the release guard.
///
/// The extension exposes the active flavor as data. Applications that want a
/// banner or other flavor indicator render it themselves.
final class FlavorsModule extends KilnModule {
  const FlavorsModule();

  @override
  String get id => 'flavors';

  @override
  Set<String> get provides => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    final flavor = registry.readOrNull<AppFlavor>();
    registry
      ..registerSingleton<ReleaseGuard>(ReleaseGuard(flavor: flavor))
      ..registerSingleton<FlavorsSupport>(FlavorsSupport(flavor: flavor));
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<FlavorsSupport>().info;
  }

  @override
  void ready(Registry registry) {
    registry.read<ReleaseGuard>().report(registry.readOrNull<AppLogger>());
  }
}
