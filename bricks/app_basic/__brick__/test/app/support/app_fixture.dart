import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{name}}/app/app.dart';
{{#minimal}}
import 'package:{{name}}/features/home/presentation/screens/home_page.dart';
{{/minimal}}

/// Builds the app root for widget tests in either template variant.
Widget buildTestApp(Registry registry) => KilnApp(
  registry: registry,
  {{#minimal}}home: const HomePage(),{{/minimal}}
);
