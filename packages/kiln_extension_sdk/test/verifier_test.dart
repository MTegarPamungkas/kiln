import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Verifier', () {
    test(
      'uses flutter for a Flutter project and stops on pub get failure',
      () async {
        final project = await copyProjectFixture('fresh_app');
        final calls = <({String executable, List<String> arguments})>[];

        final verifier = Verifier(
          runner: (executable, arguments, workingDirectory) async {
            calls.add((executable: executable, arguments: arguments));
            if (arguments.contains('get')) {
              return ProcessResult(1, 1, '', 'resolution failed');
            }
            return ProcessResult(2, 0, '', '');
          },
        );

        final result = await verifier.verify(project);

        expect(calls, hasLength(1));
        expect(calls.single.executable, 'flutter');
        expect(calls.single.arguments, ['pub', 'get']);
        expect(result.isSuccess, isFalse);
        expect(result.output, contains('resolution failed'));
        await project.delete(recursive: true);
      },
    );

    test('runs pub get and analyze and reports success', () async {
      final project = await copyProjectFixture('fresh_app');
      final calls = <List<String>>[];

      final verifier = Verifier(
        runner: (executable, arguments, workingDirectory) async {
          calls.add(arguments);
          return ProcessResult(0, 0, 'ok', '');
        },
      );

      final result = await verifier.verify(project);

      expect(calls, [
        ['pub', 'get'],
        ['analyze'],
      ]);
      expect(result.isSuccess, isTrue);
      expect(result.pubGetExitCode, 0);
      expect(result.analyzeExitCode, 0);
      await project.delete(recursive: true);
    });

    test('fails when pubspec.yaml is missing', () async {
      final empty = await Directory.systemTemp.createTemp('kiln_verify_');
      final result = await const Verifier().verify(empty);

      expect(result.isSuccess, isFalse);
      await empty.delete(recursive: true);
    });
  });
}
