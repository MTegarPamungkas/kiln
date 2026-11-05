import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/cancellation.dart';

final class _Probe extends StatefulWidget {
  const _Probe({required this.onToken});

  final ValueChanged<HttpCancelToken> onToken;

  @override
  State<_Probe> createState() => _ProbeState();
}

final class _ProbeState extends State<_Probe> with HttpCancelTokenOwner<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onToken(httpCancelToken);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('cancels the token when the widget is disposed', (tester) async {
    HttpCancelToken? token;

    await tester.pumpWidget(
      MaterialApp(home: _Probe(onToken: (value) => token = value)),
    );
    expect(token?.isCancelled, isFalse);

    await tester.pumpWidget(const SizedBox());
    expect(token?.isCancelled, isTrue);
  });
}
