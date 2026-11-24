import 'package:material_ui/material_ui.dart';
import 'package:kiln_core/kiln_core.dart';

import 'theme_mode_controller.dart';

/// Gate verbs for the theme capability.
///
/// Lets the app switch the theme mode on/off (light, dark, system) with a
/// single call returning a [Result]. The SDK owns the state, not the UI.
/// [setThemeMode] reports a [PersistOutcome] so the app can warn the user when
/// a choice applies now but will not survive a restart.
extension GateThemeX on Gate {
  ThemeModeController get themeModeController => use<ThemeModeController>();

  ThemeMode get themeMode => themeModeController.mode;

  Future<Result<PersistOutcome>> setThemeMode(ThemeMode mode) =>
      call(() => themeModeController.setMode(mode));
}
