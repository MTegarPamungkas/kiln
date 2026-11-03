import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

import 'flavor_banner.dart';
import 'release_guard.dart';

typedef AppWrapper = Widget Function(BuildContext context, Widget child);

/// Registers the flavor banner and the release guard.
final class FlavorsModule extends KilnModule {
  const FlavorsModule();

  @override
  String get id => 'flavors';

  @override
  Set<String> get provides => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    final flavor = registry.readOrNull<AppFlavor>();
    registry.registerSingleton<ReleaseGuard>(
      ReleaseGuard(flavor: flavor),
    );

    final slots = registry.readOrNull<SlotRegistry>();
    slots
        ?.open<AppWrapper>(SlotNames.appWrappers)
        .add(
          (context, child) => FlavorBanner(flavor: flavor, child: child),
          owner: 'flavors',
        );
  }

  @override
  void ready(Registry registry) {
    registry.read<ReleaseGuard>().report(registry.readOrNull<AppLogger>());
  }
}
