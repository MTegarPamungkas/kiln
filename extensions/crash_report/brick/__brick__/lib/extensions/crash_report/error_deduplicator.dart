// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

/// [CrashReporter] decorator that collapses repeated identical errors within a
/// time window so a tight failure loop cannot flood the vendor.
///
/// The key is the error's runtime type and message; distinct errors are always
/// reported. [Clock] is injectable so the window is deterministic in tests. Only
/// [captureError] is deduplicated — messages, breadcrumbs, and identity calls
/// always forward.
final class ErrorDeduplicator implements CrashReporter {
  ErrorDeduplicator({
    required CrashReporter delegate,
    Clock clock = const SystemClock(),
    Duration window = const Duration(seconds: 60),
    bool enabled = true,
  }) : _delegate = delegate,
       _clock = clock,
       _window = window,
       _enabled = enabled;

  final CrashReporter _delegate;
  final Clock _clock;
  final Duration _window;
  final bool _enabled;
  final Map<String, _DedupEntry> _seen = <String, _DedupEntry>{};

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (!_enabled) {
      return _delegate.captureError(
        error,
        stackTrace: stackTrace,
        context: context,
      );
    }
    final now = _clock.now();
    _prune(now);
    final key = _signature(error);
    final entry = _seen[key];
    if (entry != null && now.difference(entry.lastSeen) < _window) {
      entry.lastSeen = now;
      entry.count++;
      return Future<void>.value();
    }
    _seen[key] = _DedupEntry(now, (entry?.count ?? 0) + 1);
    return _delegate.captureError(
      error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) => _delegate.captureMessage(message, context: context);

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) => _delegate.addBreadcrumb(message, data: data);

  @override
  Future<void> setUser(String? userId) => _delegate.setUser(userId);

  @override
  Future<void> setContext(String key, Map<String, Object?> value) => _delegate
      .setContext(key, value);

  String _signature(Object error) => '${error.runtimeType}:$error';

  void _prune(DateTime now) {
    _seen.removeWhere(
      (_, entry) => now.difference(entry.lastSeen) >= _window,
    );
  }
}

class _DedupEntry {
  _DedupEntry(this.lastSeen, this.count);

  DateTime lastSeen;
  int count;
}
