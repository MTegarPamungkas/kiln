/// A vendor-neutral source of runtime configuration and feature flags.
///
/// Values are read synchronously from an active snapshot with caller-supplied
/// defaults, so feature-gating code never blocks on the network. Loading new
/// values is explicit ([fetch]/[fetchAndActivate]) and any backend — an HTTP
/// JSON endpoint, Firebase Remote Config, or LaunchDarkly — can implement this
/// contract.
abstract interface class RemoteConfig {
  /// Loads the latest values from the source into a pending snapshot.
  Future<void> fetch();

  /// Promotes the most recently [fetch]ed values to active.
  void activate();

  /// Convenience for [fetch] followed by [activate].
  Future<void> fetchAndActivate();

  /// Registers fallback values returned when a key has no active value.
  void setDefaults(Map<String, Object?> defaults);

  /// Reads a boolean [key], or [defaultValue] when absent.
  bool getBool(String key, {bool defaultValue = false});

  /// Reads an integer [key], or [defaultValue] when absent.
  int getInt(String key, {int defaultValue = 0});

  /// Reads a double [key], or [defaultValue] when absent.
  double getDouble(String key, {double defaultValue = 0});

  /// Reads a string [key], or [defaultValue] when absent.
  String getString(String key, {String defaultValue = ''});

  /// Reads a JSON object [key], or [defaultValue] when absent.
  Map<String, Object?> getJson(
    String key, {
    Map<String, Object?> defaultValue = const <String, Object?>{},
  });

  /// Emits whenever the active snapshot changes after an activation.
  Stream<void> get changes;
}
