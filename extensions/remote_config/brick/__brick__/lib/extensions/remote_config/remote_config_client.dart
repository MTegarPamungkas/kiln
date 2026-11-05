import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'remote_config_config.dart';
import 'remote_config_failure_mapper.dart';
import 'remote_config_gateway.dart';

/// [RemoteConfig] implementation backed by a [RemoteConfigGateway].
///
/// Reads are synchronous against an active snapshot layered over
/// application-set defaults, so feature-gating code never blocks. An empty
/// endpoint ([RemoteConfigConfig.isNoop]) skips the network entirely and serves
/// only defaults.
final class RemoteConfigClient implements RemoteConfig {
  RemoteConfigClient({
    required this.config,
    required RemoteConfigGateway gateway,
    RemoteConfigFailureMapper failureMapper =
        const RemoteConfigFailureMapper(),
  }) : _gateway = gateway,
       _mapper = failureMapper;

  final RemoteConfigConfig config;
  final RemoteConfigGateway _gateway;
  final RemoteConfigFailureMapper _mapper;

  final Map<String, Object?> _defaults = <String, Object?>{};
  final Map<String, Object?> _pending = <String, Object?>{};
  final Map<String, Object?> _active = <String, Object?>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Future<void> fetch() async {
    if (config.isNoop) {
      return;
    }
    try {
      final values = await _gateway.load(
        config.endpoint,
        timeout: config.requestTimeout,
      );
      _pending
        ..clear()
        ..addAll(values);
    } on Object catch (error, stackTrace) {
      throw _mapper.map(error, stackTrace: stackTrace);
    }
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
      return value.map((Object? k, Object? v) => MapEntry('$k', v));
    }
    return defaultValue;
  }

  /// Closes the change stream and releases the gateway.
  Future<void> close() async {
    if (!_changes.isClosed) {
      await _changes.close();
    }
    await _gateway.close();
  }
}
