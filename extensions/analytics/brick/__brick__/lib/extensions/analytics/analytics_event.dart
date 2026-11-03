import 'package:kiln_core/kiln_core.dart';

/// A typed analytics event: a stable [name] plus JSON-like [properties].
///
/// Prefer `object verb` names such as `project created` and snake_case
/// property keys. Values must be supported by `PropertySanitizer`.
final class AnalyticsEvent {
  const AnalyticsEvent(this.name, {this.properties = const <String, Object?>{}});

  final String name;
  final Map<String, Object?> properties;

  @override
  String toString() => 'AnalyticsEvent($name, $properties)';
}

/// Captures an [AnalyticsEvent] through any [Analytics] implementation.
extension AnalyticsEventCapture on Analytics {
  Future<void> captureEvent(AnalyticsEvent event) =>
      capture(event.name, properties: event.properties);
}
