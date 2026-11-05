import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import 'theme_mode_controller.dart';

/// Gate verbs for the theme capability.
///
/// Lets the app switch the theme mode on/off (light, dark, system) with a
/// single call returning a [Result]. The SDK owns the state, not the UI.
extension GateThemeX on Gate {
  ThemeModeController get themeModeController => use<ThemeModeController>();

  ThemeMode get themeMode => themeModeController.mode;

  Future<Result<void>> setThemeMode(ThemeMode mode) =>
      call<void>(() => themeModeController.setMode(mode));
}
