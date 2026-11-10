import 'package:flutter/widgets.dart';

/// Copy seam implemented by the `l10n` extension.
///
/// Kiln apps always install `l10n`, so every shell string comes from ARB.
abstract interface class CoreCopy {
  String appTitle(BuildContext context);

  String readyTitle(BuildContext context);

  String readyBody(BuildContext context);

  String starterHint(BuildContext context);

  String errorTitle(BuildContext context);

  String errorBody(BuildContext context);

  String retry(BuildContext context);
}
