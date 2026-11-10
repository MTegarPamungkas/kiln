import 'package:kiln_core/kiln_core.dart';

import 'app_route.dart';
import '../features/home/presentation/screens/home_page.dart';

/// Contributes the application root route to whatever router is installed.
///
/// `AppShell` mounts a `MaterialApp.router` as soon as the `go_router`
/// extension registers a `RouterConfig`, and that router only knows the routes
/// already contributed to the `router.routes` slot when it is built. Without
/// this module the generated home page would be ignored and the app would open
/// on a "no routes for location: /" error.
///
/// Register it before the extension modules so the slot exists first.
final class AppRoutesModule extends KilnModule {
  const AppRoutesModule();

  @override
  String get id => 'app.routes';

  @override
  void register(Registry registry) {
    var slots = registry.readOrNull<SlotRegistry>();
    if (slots == null) {
      slots = SlotRegistry();
      registry.registerSingleton<SlotRegistry>(slots);
    }

    final routes = slots.open<AppRoute>(SlotNames.routerRoutes);
    if (routes.items.any((route) => route.path == '/')) {
      return;
    }
    routes.add(
      AppRoute(path: '/', name: 'home', builder: (_) => const HomePage()),
      owner: 'app',
    );
  }
}
