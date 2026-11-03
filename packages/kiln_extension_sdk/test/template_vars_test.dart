import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('buildTemplateVars', () {
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
