import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/app/app.dart';

import 'package:with_appwrite/features/home/presentation/screens/home_page.dart';

/// Builds the app root for widget tests in either template variant.
Widget buildTestApp(Registry registry) =>
    KilnApp(registry: registry, home: const HomePage());
