import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_registry.dart';

/// Provides a test [Registry] to the widget tree.
final class TestRegistryScope extends InheritedWidget {
  const TestRegistryScope({
    required this.registry,
    required super.child,
    super.key,
  });

  final Registry registry;

  static Registry of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TestRegistryScope>();
    if (scope == null) {
      throw StateError('No TestRegistryScope found above this widget');
    }
    return scope.registry;
  }

  @override
  bool updateShouldNotify(TestRegistryScope oldWidget) =>
      registry != oldWidget.registry;
}

/// Pumps [child] inside a MaterialApp with a registry-backed scope.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Registry? registry,
  ThemeData? theme,
  Locale? locale,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en')],
}) async {
  final effectiveRegistry = registry ?? createTestRegistry();

  await tester.pumpWidget(
    TestRegistryScope(
      registry: effectiveRegistry,
      child: MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: child,
      ),
    ),
  );
}
