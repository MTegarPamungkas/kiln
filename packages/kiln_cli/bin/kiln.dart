import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';

Future<void> main(List<String> arguments) async {
  final runner = buildKilnCommandRunner();
  final code = await runner.run(arguments);
  exit(code);
}
