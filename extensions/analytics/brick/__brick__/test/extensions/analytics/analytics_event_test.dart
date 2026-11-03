import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_event.dart';

void main() {
  test('AnalyticsEvent carries a typed name and properties', () {
    const event = AnalyticsEvent(
      'project created',
      properties: <String, Object?>{'plan': 'pro', 'seats': 3},
    );

    expect(event.name, 'project created');
    expect(event.properties, <String, Object?>{'plan': 'pro', 'seats': 3});
    expect(event.toString(), contains('project created'));
  });

  test('AnalyticsEvent defaults to empty properties', () {
    const event = AnalyticsEvent('app opened');

    expect(event.properties, isEmpty);
  });

  test('captureEvent forwards the event to the Analytics implementation', () async {
    final analytics = FakeAnalytics();

    await analytics.captureEvent(
      const AnalyticsEvent(
        'project created',
        properties: <String, Object?>{'plan': 'pro'},
      ),
    );

    expect(analytics.events, hasLength(1));
    expect(analytics.events.single.name, 'project created');
    expect(analytics.events.single.properties['plan'], 'pro');
  });
}
