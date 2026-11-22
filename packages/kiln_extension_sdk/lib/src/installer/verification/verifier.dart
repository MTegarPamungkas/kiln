import 'dart:async';
import 'dart:convert';
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
  const Verifier({this.runner, this.timeout = const Duration(minutes: 5)});

  final CommandRunner? runner;

  /// Upper bound for one verification command; a hung process is killed.
  final Duration timeout;

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
  ) async {
    final customRunner = runner;
    if (customRunner != null) {
      try {
        return await customRunner(
          executable,
          arguments,
          workingDirectory,
        ).timeout(timeout);
      } on TimeoutException {
        throw TimeoutException(
          'Verification command timed out: $executable ${arguments.join(' ')}',
          timeout,
        );
      }
    }
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return ProcessResult(
        process.pid,
        exitCode,
        await stdoutFuture,
        await stderrFuture,
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw TimeoutException(
        'Verification command timed out: $executable ${arguments.join(' ')}',
        timeout,
      );
    }
  }
}
