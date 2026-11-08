import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import 'app/app.dart';
import 'app/error_screen.dart';
import 'core/error/global_error_handler.dart';
import 'extensions/extensions.g.dart';
{{#minimal}}
import 'features/home/presentation/screens/home_page.dart';
{{/minimal}}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Registry registry;
  try {
    registry = await KilnBootstrap.run(modules: kilnModules());
  } catch (error, stackTrace) {
    runApp(KilnBootstrapFailureApp(error: error, stackTrace: stackTrace));
    return;
  }

  installGlobalErrorHandlers(registry);
  runApp(
    KilnApp(
      registry: registry,
      {{#minimal}}home: const HomePage(),{{/minimal}}
    ),
  );
}
