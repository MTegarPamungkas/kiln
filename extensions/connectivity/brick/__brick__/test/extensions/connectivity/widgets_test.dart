import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/connectivity/widgets/network_status_builder.dart';
import 'package:{{app_name}}/extensions/connectivity/widgets/offline_banner.dart';

void main() {
  testWidgets('offline banner appears only while offline', (tester) async {
    final monitor = FakeConnectivity(initial: NetworkStatus.unknown);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: OfflineBanner(monitor: monitor))),
    );
    expect(find.text('Anda sedang offline'), findsNothing);

    monitor.setStatus(NetworkStatus.offline);
    await tester.pump();
    expect(find.text('Anda sedang offline'), findsOneWidget);

    monitor.setStatus(NetworkStatus.online);
    await tester.pump();
    expect(find.text('Anda sedang offline'), findsNothing);
    await monitor.dispose();
  });

  testWidgets('network status builder rebuilds by status', (tester) async {
    final monitor = FakeConnectivity(initial: NetworkStatus.online);
    await tester.pumpWidget(
      MaterialApp(
        home: NetworkStatusBuilder(
          monitor: monitor,
          builder: (context, status) => Text(status.name),
        ),
      ),
    );
    expect(find.text('online'), findsOneWidget);

    monitor.setStatus(NetworkStatus.offline);
    await tester.pump();
    expect(find.text('offline'), findsOneWidget);
    await monitor.dispose();
  });
}
