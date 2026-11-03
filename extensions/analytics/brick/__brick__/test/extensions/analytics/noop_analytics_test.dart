import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_event.dart';
import 'package:{{app_name}}/extensions/analytics/noop_analytics.dart';

void main() {
  group('NoopAnalytics', () {
    test('capture, identify, and reset complete without side effects', () async {
      const Analytics analytics = NoopAnalytics();

      await analytics.capture(
        'project created',
        properties: <String, Object?>{'plan': 'pro'},
      );
      await analytics.identify('user-1', traits: const {'role': 'owner'});
      await analytics.reset();
    });

    test('accepts typed events through captureEvent', () async {
      const Analytics analytics = NoopAnalytics();

      await analytics.captureEvent(const AnalyticsEvent('app opened'));
    });
  });
}
