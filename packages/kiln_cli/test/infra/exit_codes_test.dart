import 'package:kiln_cli/kiln_cli.dart';
import 'package:test/test.dart';

void main() {
  test('exit codes stay stable for CI', () {
    expect(ExitCodes.success, 0);
    expect(ExitCodes.usage, 64);
    expect(ExitCodes.project, 65);
    expect(ExitCodes.conflict, 66);
    expect(ExitCodes.network, 69);
    expect(ExitCodes.verification, 70);
    expect(ExitCodes.internal, 71);
  });
}
