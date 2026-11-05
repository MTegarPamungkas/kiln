import 'dart:io';

import 'package:mason/mason.dart';

/// Warns before rendering when the project already has a `build.yaml`, which
/// the codegen brick is about to overwrite so the user can merge by hand.
Future<void> preGenerate(FileContext context) async {
  final logger = Logger();
  if (File('build.yaml').existsSync()) {
    logger.warn(
      'A build.yaml already exists; the codegen brick will overwrite it. '
      'Review the diff after install and merge any custom builder options.',
    );
  }
}
