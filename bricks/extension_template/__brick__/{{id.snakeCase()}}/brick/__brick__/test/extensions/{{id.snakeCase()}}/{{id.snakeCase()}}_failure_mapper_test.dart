import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import '../../../lib/extensions/{{id.snakeCase()}}/{{id.snakeCase()}}_failure_mapper.dart';

void main() {
  test('maps unexpected errors to Failure', () {
    final failure = map{{id.pascalCase()}}Error(StateError('broken'));

    expect(failure.code, FailureCode.unexpected);
    expect(failure.cause, isA<StateError>());
  });
}
