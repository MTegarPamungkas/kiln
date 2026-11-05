import 'dart:io';

/// Runs external tools such as flutter and dart.
class ProcessRunner {
  const ProcessRunner();

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    Map<String, String>? environment,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell || Platform.isWindows,
      environment: environment,
    );
  }

  Future<ProcessResult> flutter(
    List<String> arguments, {
    String? workingDirectory,
  }) {
    return run('flutter', arguments, workingDirectory: workingDirectory);
  }

  Future<ProcessResult> dart(
    List<String> arguments, {
    String? workingDirectory,
  }) {
    return run('dart', arguments, workingDirectory: workingDirectory);
  }
}
