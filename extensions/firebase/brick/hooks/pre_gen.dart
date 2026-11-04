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
        'The flutterfire CLI did not respond. Run the manual step '
        'firebase_flutterfire_configure before building.',
      );
    }
  } on ProcessException {
    context.logger.warn(
      'The flutterfire CLI was not found. Install it with '
      '`dart pub global activate flutterfire_cli`, then run '
      '`flutterfire configure`.',
    );
  } on Object {
    context.logger.warn(
      'The flutterfire CLI check was skipped. Complete the manual step '
      'firebase_flutterfire_configure before building.',
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
        '$path does not exist yet. Run `flutterfire configure` so '
        'FirebaseOptions is generated for every platform.',
      );
    }
  } on Object {
    context.logger.warn(
      'The firebase_options.dart check was skipped. Make sure the file '
      'exists before building.',
    );
  }
}
