import 'package:flutter/widgets.dart';
import 'package:full_stack/core/l10n/core_copy.dart';

/// Test copy used by app-level widget tests without the l10n extension.
final class TestCoreCopy implements CoreCopy {
  const TestCoreCopy();

  @override
  String appTitle(BuildContext context) => 'Test App';

  @override
  String readyTitle(BuildContext context) => 'Ready';

  @override
  String readyBody(BuildContext context) => 'The app is ready.';

  @override
  String starterHint(BuildContext context) => 'Install an extension.';

  @override
  String errorTitle(BuildContext context) => 'Startup failed';

  @override
  String errorBody(BuildContext context) => 'Check the configuration.';

  @override
  String retry(BuildContext context) => 'Retry';
}
