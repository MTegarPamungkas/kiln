import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('buildTemplateVars', () {
    test('generated expressions compile and use build defines instead of shell values', () async {
      final extension = makeExtension(
        id: 'client',
        prompts: const [PromptSpec(name: 'key', type: PromptType.secret)],
      );
      final reference = buildTemplateVars(
        extension: extension,
        answers: const {'key': 'env:CLIENT_KEY'},
      )['key_dart'];
      const literalValue = 'quote" and \$variable\nnext';
      final literal = buildTemplateVars(
        extension: extension,
        answers: const {'key': literalValue},
      )['key_dart'];
      final directory = await Directory.systemTemp.createTemp(
        'kiln_client_value_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final script = File('${directory.path}/client_value.dart');
      await script.writeAsString(
        "import 'dart:convert';\n"
        'void main() { print(jsonEncode([$reference, $literal])); }',
      );
      for (final defined in [false, true]) {
        final result = await Process.run(
          Platform.resolvedExecutable,
          [if (defined) '-DCLIENT_KEY=from-build', script.path],
          environment: {'CLIENT_KEY': 'not-a-build-define'},
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(jsonDecode('${result.stdout}'), [
          defined ? 'from-build' : '',
          literalValue,
        ]);
      }
    });
    test(
      'renders build-variable references without reading process values',
      () {
        final extension = makeExtension(
          id: 'client',
          prompts: const [
            PromptSpec(name: 'key', type: PromptType.secret, required: true),
          ],
        );
        final vars = buildTemplateVars(
          extension: extension,
          answers: const {'key': 'env:CLIENT_KEY'},
        );
        expect(vars['key'], 'env:CLIENT_KEY');
        expect(
          vars['key_dart'],
          "const String.fromEnvironment('CLIENT_KEY')",
        );
        expect(
          () => buildTemplateVars(
            extension: extension,
            answers: const {'key': 'env:bad-name'},
          ),
          throwsA(isA<PromptAnswerException>()),
        );
      },
    );

    test('literal client values are escaped as Dart string expressions', () {
      final extension = makeExtension(
        id: 'client',
        prompts: const [PromptSpec(name: 'key', type: PromptType.secret)],
      );
      final vars = buildTemplateVars(
        extension: extension,
        answers: const {'key': 'quote" and \$variable\nnext'},
      );
      expect(vars['key_dart'], startsWith("'quote\""));
      expect(vars['key_dart'], contains(r'\$variable\nnext'));
    });
    test('creates id aliases and applies prompt defaults and answers', () {
      final extension = makeExtension(
        id: 'http_retry',
        name: 'HTTP retry',
        prompts: const [
          PromptSpec(
            name: 'attempts',
            type: PromptType.intValue,
            defaultValue: 3,
          ),
          PromptSpec(name: 'base_url', type: PromptType.url, required: true),
        ],
      );

      final vars = buildTemplateVars(
        extension: extension,
        answers: const {'base_url': 'https://api.kiln.dev'},
        project: const {'name': 'my_app', 'org': 'com.example'},
      );

      expect(vars['id'], 'http_retry');
      expect(vars['id_pascal'], 'HttpRetry');
      expect(vars['id_camel'], 'httpRetry');
      expect(vars['id_param'], 'http-retry');
      expect(vars['app_name'], 'my_app');
      expect(vars['org'], 'com.example');
      expect(vars['attempts'], 3);
      expect(vars['base_url'], 'https://api.kiln.dev');
    });

    test('throws for a missing required prompt', () {
      final extension = makeExtension(
        id: 'feature',
        prompts: const [
          PromptSpec(name: 'token', type: PromptType.secret, required: true),
        ],
      );

      expect(
        () => buildTemplateVars(extension: extension),
        throwsA(isA<PromptAnswerException>()),
      );
    });

    test('validates a provided answer', () {
      final extension = makeExtension(
        id: 'feature',
        prompts: const [
          PromptSpec(name: 'timeout', type: PromptType.intValue, min: 1),
        ],
      );

      expect(
        () => buildTemplateVars(
          extension: extension,
          answers: const {'timeout': 0},
        ),
        throwsA(isA<PromptAnswerException>()),
      );
    });
  });
}
