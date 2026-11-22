import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'remote_config_cache.dart';
import 'remote_config_config.dart';
import 'remote_config_failure_mapper.dart';
import 'remote_config_gateway.dart';

/// [RemoteConfig] implementation backed by a [RemoteConfigGateway].
///
/// Reads are synchronous against an active snapshot layered over
/// application-set defaults, so feature-gating code never blocks. An empty
/// endpoint ([RemoteConfigConfig.isNoop]) skips the network entirely and serves
/// only defaults. With a [RemoteConfigCache], every successful fetch is stored
/// and [activateCached] can serve the last-known-good values while the endpoint
/// is unreachable.
final class RemoteConfigClient implements RemoteConfig {
  RemoteConfigClient({
    required this.config,
    required this.gateway,
    this.cache,
    RemoteConfigFailureMapper failureMapper = const RemoteConfigFailureMapper(),
  }) : _mapper = failureMapper;

  final RemoteConfigConfig config;
  final RemoteConfigGateway gateway;

  /// Optional last-known-good snapshot store.
  final RemoteConfigCache? cache;
  final RemoteConfigFailureMapper _mapper;

  final Map<String, Object?> _defaults = <String, Object?>{};
  final Map<String, Object?> _pending = <String, Object?>{};
  final Map<String, Object?> _active = <String, Object?>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _fetchGeneration = 0;
  Future<void> _fetchTail = Future<void>.value();
  Future<void>? _closing;
  Object? _lastFetchFailure;
  bool _usingCachedValues = false;

  /// The last fetch failure, or null after a successful fetch.
  Object? get lastFetchFailure => _lastFetchFailure;

  /// Whether the active values came from the persisted snapshot.
  bool get isUsingCachedValues => _usingCachedValues;

  void _ensureOpen() {
    if (_closing != null) {
      throw StateError('Remote config is closed.');
    }
  }

  @override
  Future<void> fetch() {
    _ensureOpen();
    if (config.isNoop) {
      return Future<void>.value();
    }
    final generation = ++_fetchGeneration;
    final result = _fetchTail.then((_) async {
      if (_closing != null || generation != _fetchGeneration) {
        return;
      }
      final values = await gateway.load(
        config.endpoint,
        timeout: config.requestTimeout,
      );
      // A newer fetch superseded this one while it was in flight.
      if (_closing != null || generation != _fetchGeneration) {
        return;
      }
      _pending
        ..clear()
        ..addAll(values);
      _lastFetchFailure = null;
      await _persist(values);
    });
    _fetchTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result.catchError((Object error, StackTrace stackTrace) {
      final failure = _mapper.map(error, stackTrace: stackTrace);
      _lastFetchFailure = failure;
      throw failure;
    });
  }

  /// Applies the persisted snapshot when it is still within
  /// [RemoteConfigConfig.cacheTtl]. Returns false when nothing usable is stored.
  Future<bool> activateCached() async {
    _ensureOpen();
    final store = cache;
    if (store == null || !config.cacheEnabled) {
      return false;
    }
    final RemoteConfigSnapshot? snapshot;
    try {
      snapshot = await store.load();
    } on Object {
      return false;
    }
    if (snapshot == null) {
      return false;
    }
    final age = DateTime.now().toUtc().difference(snapshot.fetchedAt.toUtc());
    if (age > config.cacheTtl) {
      return false;
    }
    if (_closing != null) {
      return false;
    }
    _pending
      ..clear()
      ..addAll(snapshot.values);
    _active
      ..clear()
      ..addAll(snapshot.values);
    _usingCachedValues = true;
    if (!_changes.isClosed) {
      _changes.add(null);
    }
    return true;
  }

  /// Drops the persisted snapshot; a later [activateCached] finds nothing.
  Future<void> clearCache() async {
    try {
      await cache?.clear();
    } on Object {
      // Clearing is best effort.
    }
  }

  Future<void> _persist(Map<String, Object?> values) async {
    final store = cache;
    if (store == null || !config.cacheEnabled) {
      return;
    }
    try {
      await store.save(
        RemoteConfigSnapshot(
          values: Map<String, Object?>.of(values),
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
    } on Object {
      // A cache write must not turn a successful fetch into a failure.
    }
  }

  @override
  void activate() {
    _ensureOpen();
    _active
      ..clear()
      ..addAll(_pending);
    _usingCachedValues = false;
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  @override
  Future<void> fetchAndActivate() async {
    final pending = fetch();
    final generation = _fetchGeneration;
    await pending;
    if (_closing == null && generation == _fetchGeneration) {
      activate();
    }
  }

  @override
  void setDefaults(Map<String, Object?> defaults) {
    _ensureOpen();
    _defaults.addAll(defaults);
  }

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
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final value = _raw(key);
    if (value is num && value.isFinite) {
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
    await (_closing ??= _close());
  }

  Future<void> _close() async {
    ++_fetchGeneration;
    // Close the transport promptly; do not wait for an uncooperative request.
    try {
      await gateway.close();
    } finally {
      await _changes.close();
    }
  }
}
