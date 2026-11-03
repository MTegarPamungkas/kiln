import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import 'package:{{app_name}}/app/app.dart';
import 'package:{{app_name}}/app/error_screen.dart';
import 'package:{{app_name}}/core/error/global_error_handler.dart';
import 'package:{{app_name}}/extensions/extensions.g.dart';

/// The flavors compiled into this application.
abstract final class AppFlavors {
  static const development = AppFlavor.development;
  static const staging = AppFlavor.staging;
  static const production = AppFlavor.production;

  static const values = <AppFlavor>[
    {{#flavors}}AppFlavor.{{.}},
    {{/flavors}}
  ];
}

/// Registers the flavor before the rest of the modules run.
final class AppFlavorModule extends KilnModule {
  const AppFlavorModule(this.flavor);

  final AppFlavor flavor;

  @override
  String get id => 'app_flavor';

  @override
  Set<String> get provides => const <String>{'app_flavor'};

  @override
  void register(Registry registry) {
    registry.registerSingleton<AppFlavor>(flavor);
  }
}

/// Boots the application with [flavor] already registered.
Future<void> runKilnApp(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final Registry registry;
  try {
    registry = await KilnBootstrap.run(
      modules: <KilnModule>[AppFlavorModule(flavor), ...kilnModules()],
    );
  } catch (error, stackTrace) {
    runApp(KilnBootstrapFailureApp(error: error, stackTrace: stackTrace));
    return;
  }

  installGlobalErrorHandlers(registry);
  runApp(KilnApp(registry: registry));
}
