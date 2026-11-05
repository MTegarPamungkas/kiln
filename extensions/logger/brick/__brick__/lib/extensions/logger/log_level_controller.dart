import 'package:kiln_core/kiln_core.dart';

/// Holds the level used by the logger at runtime.
///
/// Only non-production flavors may change the level. In production
/// [setLevel] throws a documented [Failure] so a stray debug call cannot turn
/// verbose logging on in a shipped build.
final class LogLevelController {
  LogLevelController({
    required LogLevel initialLevel,
    required this.flavor,
    this.onChanged,
  }) : _level = initialLevel;

  final AppFlavor flavor;

  /// Called after a successful change.
  final void Function(LogLevel level)? onChanged;

  LogLevel _level;

  /// Current threshold; records below it are dropped.
  LogLevel get level => _level;

  /// Whether [setLevel] may change the level for this flavor.
  bool get canChange => !flavor.isProduction;

  /// Raises or lowers the threshold.
  ///
  /// Throws a [Failure] with [FailureCode.validationUnsupportedValue] when the
  /// flavor is production.
  void setLevel(LogLevel newLevel) {
    if (!canChange) {
      throw const Failure(
        code: FailureCode.validationUnsupportedValue,
        message: 'Log level cannot be changed in the production flavor.',
        kind: FailureKind.validation,
      );
    }
    if (newLevel == _level) {
      return;
    }
    _level = newLevel;
    onChanged?.call(newLevel);
  }
}
