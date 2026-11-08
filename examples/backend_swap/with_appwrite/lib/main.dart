import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import 'app/app.dart';
import 'app/error_screen.dart';
import 'core/error/global_error_handler.dart';
import 'extensions/extensions.g.dart';
import 'features/notes/feature.dart';

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

  // Composition root: bind the feature's domain contract to its data layer
  // once, here. `kilnModules()` is the only line that differs between the
  // backend variants, so the feature folder never changes.
  registry.registerLazySingleton<NotesRepository>(
    () => notesRepository(registry),
  );

  runApp(KilnApp(registry: registry));
}
