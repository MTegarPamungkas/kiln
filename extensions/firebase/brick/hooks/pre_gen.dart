import 'dart:io';

import 'package:mason/mason.dart';

/// Warns about the manual FlutterFire setup without ever failing generation.
///
/// Hooks run on the user's machine, so a missing CLI or generated file must
/// not abort `kiln ext add`: the install continues and `doctor` reports the
/// outstanding manual step.
void run(HookContext context) {
  _checkFlutterFireCli(context);
  _checkFirebaseOptions(context);
}

void _checkFlutterFireCli(HookContext context) {
  try {
    final result = Process.runSync('flutterfire', const <String>[
      '--version',
    ], runInShell: Platform.isWindows);
    if (result.exitCode != 0) {
      context.logger.warn(
        'flutterfire CLI tidak merespons. Jalankan langkah manual '
        'firebase_flutterfire_configure sebelum build.',
      );
    }
  } on ProcessException {
    context.logger.warn(
      'flutterfire CLI tidak ditemukan. Pasang dengan '
      '`dart pub global activate flutterfire_cli`, lalu jalankan '
      '`flutterfire configure`.',
    );
  } on Object {
    context.logger.warn(
      'Pemeriksaan flutterfire CLI dilewati. Selesaikan langkah manual '
      'firebase_flutterfire_configure sebelum build.',
    );
  }
}

void _checkFirebaseOptions(HookContext context) {
  try {
    final source = context.vars['options_source']?.toString() ?? 'generated';
    if (source != 'generated') {
      return;
    }
    final rawPath = context.vars['firebase_options_path']?.toString();
    final path = rawPath == null || rawPath.trim().isEmpty
        ? 'lib/firebase_options.dart'
        : rawPath;
    if (!File(path).existsSync()) {
      context.logger.warn(
        '$path belum ada. Jalankan `flutterfire configure` agar '
        'FirebaseOptions untuk semua platform dihasilkan.',
      );
    }
  } on Object {
    context.logger.warn(
      'Pemeriksaan firebase_options.dart dilewati. Pastikan file tersebut '
      'ada sebelum build.',
    );
  }
}
