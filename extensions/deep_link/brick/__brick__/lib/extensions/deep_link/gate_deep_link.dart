import 'package:kiln_core/kiln_core.dart';

import 'app_link_builder.dart';

/// Gate verbs for building outgoing deep links.
///
/// Incoming links stay on `gate.deepLinks` (initial link and stream). This adds
/// the outgoing builders as one-call `Result` verbs so an empty path or a missing
/// host is reported as an `Err` instead of thrown.
extension GateDeepLinkX on Gate {
  AppLinkBuilder get appLinkBuilder => use<AppLinkBuilder>();

  /// Builds a `<scheme>://...` link from [path].
  Future<Result<Uri>> buildCustomLink(
    String path, {
    Map<String, String> query = const <String, String>{},
  }) => call(() => appLinkBuilder.custom(path, query: query));

  /// Builds an `https://host/...` link from [path].
  Future<Result<Uri>> buildUniversalLink(
    String path, {
    String? host,
    Map<String, String> query = const <String, String>{},
  }) => call(() => appLinkBuilder.universal(path, host: host, query: query));
}
