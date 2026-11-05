import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

/// Provides the [Registry] explicitly instead of a global singleton.
class RegistryScope extends InheritedWidget {
  const RegistryScope({
    required this.registry,
    required super.child,
    super.key,
  });

  final Registry registry;

  static Registry of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RegistryScope>();
    if (scope == null) {
      throw StateError('No RegistryScope found above this widget');
    }
    return scope.registry;
  }

  static T read<T extends Object>(BuildContext context) =>
      of(context).read<T>();

  static T? readOrNull<T extends Object>(BuildContext context) =>
      of(context).readOrNull<T>();

  @override
  bool updateShouldNotify(RegistryScope oldWidget) =>
      registry != oldWidget.registry;
}
