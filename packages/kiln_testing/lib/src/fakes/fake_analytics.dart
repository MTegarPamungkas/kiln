import 'package:kiln_core/kiln_core.dart';

/// One captured analytics event.
final class AnalyticsEventRecord {
  const AnalyticsEventRecord(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;
}

/// One identified analytics user.
final class AnalyticsIdentityRecord {
  const AnalyticsIdentityRecord(this.userId, this.traits);

  final String userId;
  final Map<String, Object?> traits;
}

/// [Analytics] that records calls instead of sending them.
final class FakeAnalytics implements Analytics {
  final List<AnalyticsEventRecord> events = <AnalyticsEventRecord>[];
  final List<AnalyticsIdentityRecord> identities = <AnalyticsIdentityRecord>[];
  int resetCalls = 0;

  @override
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    events.add(AnalyticsEventRecord(event, properties));
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) async {
    identities.add(AnalyticsIdentityRecord(userId, traits));
  }

  @override
  Future<void> reset() async {
    resetCalls++;
  }
}
