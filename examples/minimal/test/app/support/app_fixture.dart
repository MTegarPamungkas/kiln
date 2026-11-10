import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:minimal/app/app.dart';

import 'package:minimal/features/home/presentation/screens/home_page.dart';

/// Builds the app root for widget tests in either template variant.
Widget buildTestApp(Registry registry) =>
    KilnApp(registry: registry, home: const HomePage());
