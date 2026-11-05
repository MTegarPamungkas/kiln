import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Status and navigation bar styling for the current theme.
abstract final class SystemUiStyle {
  /// Overlay style that keeps system icons readable on [brightness].
  static SystemUiOverlayStyle forBrightness(
    Brightness brightness, {
    Color? statusBarColor,
    Color? navigationBarColor,
  }) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: statusBarColor ?? Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          navigationBarColor ??
          (isDark ? const Color(0xFF111318) : const Color(0xFFF7F9FC)),
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// Overlay style derived from the app theme surfaces.
  static SystemUiOverlayStyle fromTheme(ThemeData theme) {
    return forBrightness(
      theme.brightness,
      statusBarColor: theme.colorScheme.surface,
      navigationBarColor: theme.colorScheme.surface,
    );
  }

  /// Applies the style for [theme] to the platform channels.
  static void apply(ThemeData theme) {
    SystemChrome.setSystemUIOverlayStyle(fromTheme(theme));
  }
}
