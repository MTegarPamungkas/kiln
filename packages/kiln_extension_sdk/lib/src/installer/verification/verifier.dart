import 'dart:io';

import 'package:path/path.dart' as p;

import '../pubspec_reader.dart';

typedef CommandRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
  String workingDirectory,
);

/// Outcome of `pub get` and `analyze` after an installation.
final class VerificationResult {
  const VerificationResult({
    required this.pubGetExitCode,
    required this.analyzeExitCode,
    required this.output,
  });

  final int pubGetExitCode;
  final int analyzeExitCode;
  final String output;

  bool get isSuccess => pubGetExitCode == 0 && analyzeExitCode == 0;
}

/// Runs the verification commands declared in `kiln.yaml`.
final class Verifier {
  const Verifier({this.runner});

  final CommandRunner? runner;

  Future<VerificationResult> verify(
    Directory projectRoot, {
    bool runPubGet = true,
    bool runAnalyze = true,
  }) async {
    final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return const VerificationResult(
        pubGetExitCode: 1,
        analyzeExitCode: 1,
        output: 'pubspec.yaml not found',
      );
    }
    final info = PubspecReader(pubspecFile).read();
    final tool = info.usesFlutterSdk ? 'flutter' : 'dart';
    final output = StringBuffer();
    var pubGetExitCode = 0;
    var analyzeExitCode = 0;

    if (runPubGet) {
      final result = await _run(tool, <String>['pub', 'get'], projectRoot.path);
      pubGetExitCode = result.exitCode;
      output
        ..write(result.stdout)
        ..write(result.stderr);
      if (pubGetExitCode != 0) {
        return VerificationResult(
          pubGetExitCode: pubGetExitCode,
          analyzeExitCode: analyzeExitCode,
          output: output.toString(),
        );
      }
    }

    if (runAnalyze) {
      final result = await _run(tool, <String>['analyze'], projectRoot.path);
      analyzeExitCode = result.exitCode;
      output
        ..write(result.stdout)
        ..write(result.stderr);
    }

    return VerificationResult(
      pubGetExitCode: pubGetExitCode,
      analyzeExitCode: analyzeExitCode,
      output: output.toString(),
    );
  }

  Future<ProcessResult> _run(
    String executable,
    List<String> arguments,
    String workingDirectory,
  ) {
    final customRunner = runner;
    if (customRunner != null) {
      return customRunner(executable, arguments, workingDirectory);
    }
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
  }
}
