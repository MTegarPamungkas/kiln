import 'dart:async';

import 'package:flutter/material.dart';

import '../theme_mode_controller.dart';

/// Segmented control for the System, Light, and Dark theme modes.
final class ThemeModeSwitcher extends StatelessWidget {
  const ThemeModeSwitcher({required this.controller, super.key});

  final ThemeModeController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller.modeListenable,
      builder: (context, mode, _) {
        return SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('Sistem'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Terang'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Gelap'),
            ),
          ],
          selected: <ThemeMode>{mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            unawaited(controller.setMode(selection.first));
          },
        );
      },
    );
  }
}
