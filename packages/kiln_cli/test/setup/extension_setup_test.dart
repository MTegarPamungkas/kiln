import 'package:kiln_cli/kiln_cli.dart';
import 'package:kiln_cli/src/setup/extension_setup.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

const prompts = [
  PromptSpec(name: 'url', type: PromptType.url, required: true),
  PromptSpec(
    name: 'token',
    type: PromptType.secret,
    secret: true,
    required: true,
  ),
  PromptSpec(name: 'enabled', type: PromptType.boolValue, defaultValue: true),
  PromptSpec(
    name: 'count',
    type: PromptType.intValue,
    defaultValue: 3,
    min: 1,
    max: 10,
  ),
  PromptSpec(
    name: 'mode',
    type: PromptType.enumValue,
    defaultValue: 'light',
    options: ['light', 'dark'],
  ),
  PromptSpec(
    name: 'items',
    type: PromptType.multi,
    defaultValue: ['one'],
    options: ['one', 'two'],
  ),
  PromptSpec(name: 'prefix', type: PromptType.string, defaultValue: ''),
];

const setup = ExtensionSetup(
  ExtensionManifest(
    id: 'example',
    name: 'Example',
    version: '0.1.0',
    description: 'Example',
    category: 'example',
    prompts: prompts,
  ),
);

void main() {
  test('interactive input handles every prompt type and preserves string whitespace', () {
    final input = [
      'https://api.example.com',
      'new_client_token',
      'false',
      '8',
      'dark',
      'one,two',
      'Bearer ',
    ].iterator;
    final output = <String>[];
    final values = setup.collect(
      saved: const {},
      provided: const {},
      interactive: true,
      prompter: Prompter(
        readLine: (_) => input.moveNext() ? input.current : null,
        write: output.add,
      ),
    );
    expect(values, {
      'url': 'https://api.example.com',
      'token': 'new_client_token',
      'enabled': false,
      'count': 8,
      'mode': 'dark',
      'items': ['one', 'two'],
      'prefix': 'Bearer ',
    });
    expect(output.join(), isNot(contains('new_client_token')));
  });

  test('secret defaults are masked and retained through copied prompters', () {
    final output = <String>[];
    final prompter = Prompter(
      readLine: (_) => '',
      write: output.add,
    ).withAssumeYes(false);
    final values = setup.collect(
      saved: {'url': 'https://api.example.com', 'token': 'private_saved_value'},
      provided: const {},
      interactive: true,
      prompter: prompter,
    );
    expect(values['token'], 'private_saved_value');
    expect(output.join(), contains('[set; Enter to keep]'));
    expect(output.join(), isNot(contains('private_saved_value')));
  });

  test('invalid values and list members are not echoed by diagnostics', () {
    final issues = setup.issues({
      'url': 'private_invalid_value',
      'token': '',
      'enabled': 'private_invalid_value',
      'count': 99,
      'mode': 'private_invalid_value',
      'items': ['private_invalid_value'],
    });
    expect(
      issues.keys,
      containsAll(['url', 'token', 'enabled', 'count', 'mode', 'items']),
    );
    expect(issues.values.join(), isNot(contains('private_invalid_value')));
  });

  test(
    'explicit values override saved values and !clear empties optional lists',
    () {
      final input = ['', '', '', '', '!clear', ''].iterator;
      final values = setup.collect(
        saved: {
          'url': 'https://api.example.com',
          'token': 'saved_client_token',
        },
        provided: {'example.count': '7'},
        interactive: true,
        prompter: Prompter(
          readLine: (_) => input.moveNext() ? input.current : null,
          write: (_) {},
        ),
      );
      // The count prompt is skipped because an explicit answer was supplied.
      expect(values['count'], 7);
      expect(values['items'], isEmpty);
    },
  );

  test('fallback locale must belong to selected locales', () {
    final localization = ExtensionSetup(
      findAvailableExtension('l10n')!.manifest,
    );
    expect(
      localization.issues({
        'locales': ['en'],
        'fallback_locale': 'id',
      }),
      contains('locales'),
    );
  });
}
