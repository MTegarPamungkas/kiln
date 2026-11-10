import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import 'app/app.dart';
import 'app/app_routes_module.dart';
import 'app/error_screen.dart';
import 'core/error/global_error_handler.dart';
import 'extensions/extensions.g.dart';

import 'features/home/presentation/screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Registry registry;
  try {
    registry = await KilnBootstrap.run(
      modules: <KilnModule>[const AppRoutesModule(), ...kilnModules()],
    );
  } catch (error, stackTrace) {
    runApp(KilnBootstrapFailureApp(error: error, stackTrace: stackTrace));
    return;
  }

  installGlobalErrorHandlers(registry);
  runApp(KilnApp(registry: registry, home: const HomePage()));
}
