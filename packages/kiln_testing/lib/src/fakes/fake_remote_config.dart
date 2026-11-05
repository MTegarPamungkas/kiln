import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// [RemoteConfig] that resolves values from an in-memory source, pending
/// snapshot, active snapshot, and defaults — mirroring the fetch/activate flow
/// a real backend uses, without any network.
///
/// Tests call [seedRemote] to stage values, then [fetchAndActivate] to expose
/// them through the typed getters.
final class FakeRemoteConfig implements RemoteConfig {
  final Map<String, Object?> _source = <String, Object?>{};
  final Map<String, Object?> _pending = <String, Object?>{};
  final Map<String, Object?> _active = <String, Object?>{};
  final Map<String, Object?> _defaults = <String, Object?>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Number of times [fetch] has been called.
  int fetchCalls = 0;

  /// When true, [fetch] throws, simulating an unreachable source.
  bool fetchFails = false;

  /// Stage the values that the next [fetch] will return.
  void seedRemote(Map<String, Object?> values) {
    _source
      ..clear()
      ..addAll(values);
  }

  @override
  Future<void> fetch() async {
    fetchCalls++;
    if (fetchFails) {
      throw StateError('remote config fetch failed');
    }
    _pending
      ..clear()
      ..addAll(_source);
  }

  @override
  void activate() {
    _active
      ..clear()
      ..addAll(_pending);
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  @override
  Future<void> fetchAndActivate() async {
    await fetch();
    activate();
  }

  @override
  void setDefaults(Map<String, Object?> defaults) => _defaults.addAll(defaults);

  @override
  Stream<void> get changes => _changes.stream;

  Object? _raw(String key) =>
      _active.containsKey(key) ? _active[key] : _defaults[key];

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _raw(key);
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value == 'true';
    }
    return defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final value = _raw(key);
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  @override
  double getDouble(String key, {double defaultValue = 0}) {
    final value = _raw(key);
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    final value = _raw(key);
    return value == null ? defaultValue : '$value';
  }

  @override
  Map<String, Object?> getJson(
    String key, {
    Map<String, Object?> defaultValue = const <String, Object?>{},
  }) {
    final value = _raw(key);
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', v));
    }
    return defaultValue;
  }

  Future<void> dispose() => _changes.close();
}
