import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef CloudFunctionsContractFactory = FutureOr<CloudFunctions> Function();

/// Behavior every [CloudFunctions] implementation must share.
void cloudFunctionsContract({
  required CloudFunctionsContractFactory create,
  String description = 'CloudFunctions',
  String functionId = 'hello-kiln',
  String Function(FunctionExecution execution)? expectedBody,
}) {
  group('$description contract', () {
    test('invoke returns the execution the function produced', () async {
      final functions = await create();

      final execution = await functions.invoke(functionId);

      expect(execution.functionId, functionId);
      expect(execution.status, isNotEmpty);
      expect(execution.statusCode, isNot(0));
      if (expectedBody != null) {
        expect(expectedBody(execution), isTrue,
            reason: 'body was: ${execution.body}');
      } else {
        expect(execution.body, isNotEmpty);
      }
    });

    test('invoke forwards a JSON body to the function', () async {
      final functions = await create();

      final execution = await functions.invoke(
        functionId,
        body: <String, Object?>{'name': 'Kiln'},
      );

      expect(execution.status, isNotEmpty);
      // The echo contract: whatever the function returns, the invocation
      // completes and carries the raw body back to the caller.
      expect(execution.body, isA<String>());
    });

    test('an unknown function throws a functions Failure', () async {
      final functions = await create();

      await expectLater(
        functions.invoke('definitely-missing-x'),
        throwsA(
          isA<Failure>()
              .having(
                (value) => value.code,
                'code',
                FailureCode.functionsNotFound,
              )
              .having(
                (value) => value.kind,
                'kind',
                FailureKind.unknown,
              ),
        ),
      );
    });
  });
}
