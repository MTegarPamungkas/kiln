import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Theme seam filled by the `theme` extension when it is installed.
class AppThemeConfig {
  AppThemeConfig({
    ThemeData? light,
    ThemeData? dark,
    this.mode = ThemeMode.system,
    this.modeListenable,
  }) : light = light ?? AppTheme.light,
       dark = dark ?? AppTheme.dark;

  final ThemeData light;
  final ThemeData dark;
  final ThemeMode mode;

  /// Optional live mode supplied by a theme extension.
  final ValueListenable<ThemeMode>? modeListenable;

  ThemeMode get currentMode => modeListenable?.value ?? mode;
}
