import 'package:kiln_core/kiln_core.dart';

/// Gate verbs for the remote configuration capability.
///
/// `kiln_core` exposes [Gate.remoteConfig] and [Gate.fetchRemoteConfig]; this
/// extension adds ergonomic feature checks and typed reads so application code
/// gates features through the Gate without reaching into the contract directly.
extension GateRemoteConfigX on Gate {
  /// Whether a boolean feature flag is on, falling back to [defaultValue].
  bool featureEnabled(String key, {bool defaultValue = false}) =>
      remoteConfig.getBool(key, defaultValue: defaultValue);

  /// Convenience typed reads over the active snapshot.
  int remoteConfigInt(String key, {int defaultValue = 0}) =>
      remoteConfig.getInt(key, defaultValue: defaultValue);

  double remoteConfigDouble(String key, {double defaultValue = 0}) =>
      remoteConfig.getDouble(key, defaultValue: defaultValue);

  String remoteConfigString(String key, {String defaultValue = ''}) =>
      remoteConfig.getString(key, defaultValue: defaultValue);

  Map<String, Object?> remoteConfigJson(
    String key, {
    Map<String, Object?> defaultValue = const <String, Object?>{},
  }) => remoteConfig.getJson(key, defaultValue: defaultValue);

  /// Registers caller-side fallback values on the active source.
  void setRemoteDefaults(Map<String, Object?> defaults) =>
      remoteConfig.setDefaults(defaults);

  /// Emits whenever the active configuration changes.
  Stream<void> get remoteConfigChanges => remoteConfig.changes;
}
