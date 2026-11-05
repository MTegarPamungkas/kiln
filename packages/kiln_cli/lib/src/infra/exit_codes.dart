/// Stable process exit codes used by CI.
abstract final class ExitCodes {
  static const int success = 0;
  static const int usage = 64;
  static const int project = 65;
  static const int conflict = 66;
  static const int network = 69;
  static const int verification = 70;
  static const int internal = 71;

  /// The user cancelled an interactive prompt.
  static const int cancelled = 130;
}
