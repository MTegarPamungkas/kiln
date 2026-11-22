import 'package:kiln_core/kiln_core.dart';

/// Settings for the HTTP-backed remote configuration source.
///
/// The endpoint is rendered from the install prompt. An empty endpoint makes the
/// extension a no-op that only serves caller defaults, so it can be installed
/// before a config service exists.
final class RemoteConfigConfig {
  RemoteConfigConfig({
    this.endpoint = '{{{endpoint}}}',
    this.fetchInterval = const Duration(minutes: 15),
    this.requestTimeout = const Duration(seconds: 10),
    this.cacheTtl = const Duration(hours: 24),
    this.refreshOnResume = true,
    Set<AppFlavor>? enabledFlavors,
    this.noopWhenEndpointEmpty = true,
  }) : enabledFlavors = Set<AppFlavor>.unmodifiable(
         enabledFlavors ?? defaultEnabledFlavors,
       );

  /// Flavors allowed to fetch configuration unless narrowed by the app.
  static final Set<AppFlavor> defaultEnabledFlavors = <AppFlavor>{
    AppFlavor.development,
    AppFlavor.staging,
    AppFlavor.production,
  };

  /// Values the Kiln installer writes into the application.
  static final RemoteConfigConfig defaults = RemoteConfigConfig();

  /// Absolute URL returning a JSON object of flag/config values.
  final String endpoint;

  /// Minimum time between resume-triggered refreshes.
  ///
  /// The app owns refresh cadence: the module only refreshes when the app
  /// resumes after it has been in the background for [fetchInterval]. Set
  /// [refreshOnResume] to false to disable even that.
  final Duration fetchInterval;

  /// Per-request network timeout.
  final Duration requestTimeout;

  /// How long a persisted snapshot stays usable when the endpoint cannot be
  /// reached at startup. `Duration.zero` disables the last-known-good cache.
  final Duration cacheTtl;

  /// Whether a resume after [fetchInterval] triggers a refresh.
  ///
  /// This is a foreground-only policy: it never schedules OS background work,
  /// so it adds no native dependency. Apps that want refresh while the process
  /// is dead should call [RemoteConfig.fetchAndActivate] themselves.
  final bool refreshOnResume;

  /// Whether a fresh persisted snapshot may be served.
  bool get cacheEnabled => cacheTtl > Duration.zero;

  /// Flavors allowed to hit the network.
  final Set<AppFlavor> enabledFlavors;

  /// Whether an empty [endpoint] turns the extension into a noop source.
  final bool noopWhenEndpointEmpty;

  bool get hasEndpoint => endpoint.trim().isNotEmpty;

  /// Whether this configuration intentionally fetches nothing.
  bool get isNoop => noopWhenEndpointEmpty && !hasEndpoint;

  bool isFlavorEnabled(AppFlavor? flavor) {
    if (enabledFlavors.isEmpty) {
      return false;
    }
    if (flavor == null) {
      return true;
    }
    return enabledFlavors.contains(flavor);
  }

  /// Whether the extension may fetch in [flavor].
  bool isActiveFor(AppFlavor? flavor) => !isNoop && isFlavorEnabled(flavor);

  /// Rejects values the fetcher cannot use.
  void validate() {
    final trimmed = endpoint.trim();
    if (trimmed.isNotEmpty) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        throw Failure(
          code: FailureCode.configurationInvalid,
          message:
              'Remote config endpoint "$endpoint" is not an absolute HTTP URL.',
          kind: FailureKind.configuration,
          details: <String, Object?>{'endpoint': endpoint},
        );
      }
    }
    if (fetchInterval <= Duration.zero) {
      throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Remote config fetch interval must be greater than zero.',
        kind: FailureKind.configuration,
      );
    }
    if (cacheTtl.isNegative) {
      throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Remote config cache TTL cannot be negative.',
        kind: FailureKind.configuration,
      );
    }
    if (!noopWhenEndpointEmpty && !hasEndpoint) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message: 'A remote config endpoint is required when the empty-endpoint noop is off.',
        kind: FailureKind.configuration,
      );
    }
  }

  RemoteConfigConfig copyWith({
    String? endpoint,
    Duration? fetchInterval,
    Duration? requestTimeout,
    Duration? cacheTtl,
    bool? refreshOnResume,
    Set<AppFlavor>? enabledFlavors,
    bool? noopWhenEndpointEmpty,
  }) {
    return RemoteConfigConfig(
      endpoint: endpoint ?? this.endpoint,
      fetchInterval: fetchInterval ?? this.fetchInterval,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      refreshOnResume: refreshOnResume ?? this.refreshOnResume,
      enabledFlavors: enabledFlavors ?? this.enabledFlavors,
      noopWhenEndpointEmpty:
          noopWhenEndpointEmpty ?? this.noopWhenEndpointEmpty,
    );
  }

  @override
  String toString() =>
      'RemoteConfigConfig(endpoint: $endpoint, fetchInterval: $fetchInterval, '
      'enabledFlavors: ${enabledFlavors.map((flavor) => flavor.name).join(',')}, '
      'isNoop: $isNoop)';
}
