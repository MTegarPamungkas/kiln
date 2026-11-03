import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/features/counter/counter_cubit.dart';
import 'package:{{app_name}}/features/counter/counter_page.dart';

void main() {
  testWidgets('counter page shows the value and reacts to buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider<CounterCubit>(
        create: (_) => CounterCubit(),
        child: const MaterialApp(home: CounterPage()),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('counter-increment')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('counter-decrement')));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
