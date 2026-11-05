import 'dart:async';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'deep_link_config.dart';
import 'deep_link_failure_mapper.dart';
import 'deep_link_gateway.dart';
import 'link_allowlist.dart';
import 'link_deduplicator.dart';
import 'link_normalizer.dart';
import 'pending_link_buffer.dart';

/// [DeepLinks] backed by an [AppLinksGateway].
///
/// Incoming links are normalized, filtered through [LinkAllowlist], and
/// deduplicated with [LinkDeduplicator]. Links that arrive before the first
/// listener are buffered by [PendingLinkBuffer] and replayed once.
final class DeviceDeepLinks implements DeepLinks {
  DeviceDeepLinks({
    required this.gateway,
    this.config = DeepLinkConfig.defaults,
    Clock? clock,
  }) : clock = clock ?? const SystemClock() {
    _deduplicator = LinkDeduplicator(
      clock: this.clock,
      window: config.deduplicationWindow,
    );
    _links.onListen = _scheduleReplay;
  }

  final AppLinksGateway gateway;
  final DeepLinkConfig config;
  final Clock clock;

  final StreamController<Uri> _links = StreamController<Uri>.broadcast(
    sync: true,
  );
  final PendingLinkBuffer _pending = PendingLinkBuffer();
  late final LinkDeduplicator _deduplicator;
  late final LinkAllowlist _allowlist = LinkAllowlist(config: config);
  late final LinkNormalizer _normalizer = LinkNormalizer(config: config);
  StreamSubscription<Uri>? _subscription;
  Uri? _initialLink;
  bool _started = false;
  bool _disposed = false;
  bool _replayed = false;
  bool _initialProbed = false;
  SupportInfo? _support;

  /// The last platform error; rejected links are dropped silently.
  Failure? lastFailure;

  /// Whether [start] already ran.
  bool get isStarted => _started;

  @override
  Uri? get initialLink => _initialLink;

  @override
  Stream<Uri> get links => _links.stream;

  /// Probes the platform and captures the launch link once.
  ///
  /// Called by the module before `ready`; [start] reuses the captured link so
  /// the platform is asked only once.
  Future<SupportInfo> probeSupport() async {
    final cached = _support;
    if (cached != null) {
      return cached;
    }
    _initialProbed = true;
    try {
      final initial = await gateway.initialLink();
      if (initial != null && !_disposed) {
        _initialLink = _accept(initial);
      }
      _support = const SupportInfo.supported();
    } on MissingPluginException catch (error) {
      lastFailure = mapDeepLinkError(error);
      _support = SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Deep links are not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      lastFailure = mapDeepLinkError(error);
      _support = SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Deep links are not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on Object catch (error, stackTrace) {
      lastFailure = mapDeepLinkError(error, stackTrace: stackTrace);
      _support = SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Deep links could not start: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
    return _support!;
  }

  /// Subscribes to the gateway and captures the launch link.
  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _subscription = gateway.links.listen(_handleLink, onError: _handleError);
    _started = true;
    if (_initialProbed) {
      return;
    }
    _initialProbed = true;
    try {
      final initial = await gateway.initialLink();
      if (initial == null || _disposed) {
        return;
      }
      _initialLink = _accept(initial);
    } on Object catch (error, stackTrace) {
      lastFailure = mapDeepLinkError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await gateway.dispose();
    await _links.close();
  }

  void _handleLink(Uri link) {
    final accepted = _accept(link);
    if (accepted == null || _disposed) {
      return;
    }
    if (_links.hasListener) {
      _links.add(accepted);
    } else {
      _pending.add(accepted);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    lastFailure = mapDeepLinkError(error, stackTrace: stackTrace);
  }

  Uri? _accept(Uri link) {
    final normalized = _normalizer.normalize(link);
    if (!_allowlist.allows(normalized)) {
      return null;
    }
    if (_deduplicator.isDuplicate(normalized)) {
      return null;
    }
    return normalized;
  }

  void _scheduleReplay() {
    if (_replayed || !_pending.hasPending) {
      return;
    }
    scheduleMicrotask(() {
      if (_disposed || _replayed || !_links.hasListener) {
        return;
      }
      _replayed = true;
      for (final link in _pending.release()) {
        _links.add(link);
      }
    });
  }
}
