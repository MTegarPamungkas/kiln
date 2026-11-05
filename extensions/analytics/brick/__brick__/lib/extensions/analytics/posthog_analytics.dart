// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

import 'analytics_failure_mapper.dart';
import 'analytics_gateway.dart';
import 'property_sanitizer.dart';

/// [Analytics] implementation that sends sanitized data through a gateway.
final class PosthogAnalytics implements Analytics {
  PosthogAnalytics({
    required AnalyticsGateway gateway,
    PropertySanitizer sanitizer = const PropertySanitizer(),
    AnalyticsFailureMapper failureMapper = const AnalyticsFailureMapper(),
  }) : _gateway = gateway,
       _sanitizer = sanitizer,
       _failureMapper = failureMapper;

  final AnalyticsGateway _gateway;
  final PropertySanitizer _sanitizer;
  final AnalyticsFailureMapper _failureMapper;

  @override
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    if (event.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Analytics event name must not be empty.',
        kind: FailureKind.validation,
      );
    }
    try {
      final sanitized = _sanitizer.sanitize(properties);
      await _gateway.capture(event, sanitized);
    } on Object catch (error, stackTrace) {
      throw _failureMapper.map(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) async {
    if (userId.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Analytics user id must not be empty.',
        kind: FailureKind.validation,
      );
    }
    try {
      final sanitized = _sanitizer.sanitize(traits);
      await _gateway.identify(userId, sanitized);
    } on Object catch (error, stackTrace) {
      throw _failureMapper.map(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> reset() async {
    try {
      await _gateway.reset();
    } on Object catch (error, stackTrace) {
      throw _failureMapper.map(error, stackTrace: stackTrace);
    }
  }

  /// Sends queued events as soon as possible.
  Future<void> flush() async {
    try {
      await _gateway.flush();
    } on Object catch (error, stackTrace) {
      throw _failureMapper.map(error, stackTrace: stackTrace);
    }
  }
}
