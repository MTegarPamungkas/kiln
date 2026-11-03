import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Warns when a release build uses a non-production flavor.
final class ReleaseGuard {
  const ReleaseGuard({
    required this.flavor,
    this.isRelease = kReleaseMode,
    this.isDebug = kDebugMode,
  });

  final AppFlavor? flavor;
  final bool isRelease;
  final bool isDebug;

  /// Logs one warning for a release build with a non-production flavor.
  void report(AppLogger? logger) {
    final current = flavor;
    if (!isRelease || current == null || current.isProduction) {
      return;
    }
    logger?.warning(
      'Release build uses non-production flavor ${current.name}.',
      data: <String, Object?>{'flavor': current.name},
    );
  }
}
