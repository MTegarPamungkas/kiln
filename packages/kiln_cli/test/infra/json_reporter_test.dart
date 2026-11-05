import 'package:kiln_cli/kiln_cli.dart';
import 'package:test/test.dart';

void main() {
  test('JsonReporter writes indented JSON to the provided sink', () {
    final output = <String>[];
    final reporter = JsonReporter(output.add);

    reporter.write(const <String, Object?>{'ok': true, 'count': 2});

    expect(output, hasLength(1));
    expect(output.single, contains('"ok": true'));
    expect(output.single, contains('\n'));
  });
}
