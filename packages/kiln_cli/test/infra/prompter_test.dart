import 'package:kiln_cli/kiln_cli.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Prompter', () {
    test('confirm accepts yes and falls back in non-interactive mode', () {
      final answers = <String?>['y', ''];
      var index = 0;
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => answers[index++],
        write: (_) {},
      );

      expect(prompter.confirm('Continue?'), isTrue);
      expect(prompter.confirm('Delete?', defaultValue: true), isTrue);

      final quiet = Prompter(interactive: false);
      expect(quiet.confirm('Delete?'), isFalse);
      expect(quiet.confirm('Delete?', defaultValue: true), isTrue);
    });

    test('assumeYes returns defaults without reading input', () {
      final prompter = Prompter(assumeYes: true, interactive: false);

      expect(prompter.confirm('Continue?'), isTrue);
      expect(prompter.text('Name', defaultValue: 'kiln'), 'kiln');
      expect(
        prompter.select('Mode', ['light', 'dark'], defaultValue: 'dark'),
        'dark',
      );
      expect(prompter.integer('Port', defaultValue: 8080), 8080);
    });

    test('select accepts a number or an exact option', () {
      final answers = <String?>['2', 'light'];
      var index = 0;
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => answers[index++],
        write: (_) {},
      );

      expect(prompter.select('Mode', ['light', 'dark']), 'dark');
      expect(prompter.select('Mode', ['light', 'dark']), 'light');
    });

    test('required prompts throw when non-interactive', () {
      final prompter = Prompter(interactive: false);

      expect(
        () => prompter.select('Mode', ['light', 'dark']),
        throwsA(isA<KilnException>()),
      );
    });

    test('integer validates its range', () {
      final answers = <String?>['0', '30'];
      var index = 0;
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => answers[index++],
        write: (_) {},
      );

      expect(prompter.integer('Timeout', min: 1, max: 60), 30);
    });

    test('selectMany keeps the shown selection on an empty answer', () {
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => '',
        write: (_) {},
      );

      expect(
        prompter.selectMany(
          'Platforms:',
          ['android', 'ios', 'web'],
          defaults: {'android', 'web'},
        ),
        <String>['android', 'web'],
      );
    });

    test('selectMany toggles entries by number', () {
      final answers = <String?>['1 3', '2,2'];
      var index = 0;
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => answers[index++],
        write: (_) {},
      );

      expect(
        prompter.selectMany(
          'Platforms:',
          ['android', 'ios', 'web'],
          defaults: {'ios'},
        ),
        <String>['android', 'ios', 'web'],
      );
      expect(
        prompter.selectMany('Platforms:', ['android', 'ios', 'web']),
        <String>[],
      );
    });

    test('selectMany falls back to defaults without interaction', () {
      final quiet = Prompter(interactive: false);
      expect(
        quiet.selectMany(
          'Platforms:',
          ['android', 'ios'],
          defaults: {'ios'},
        ),
        <String>['ios'],
      );
      final assumed = Prompter(assumeYes: true, interactive: false);
      expect(
        assumed.selectMany(
          'Platforms:',
          ['android', 'ios'],
          defaults: {'android'},
        ),
        <String>['android'],
      );
    });

    test('selectMany rejects a number outside the options', () {
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => '9',
        write: (_) {},
      );

      expect(
        () => prompter.selectMany('Platforms:', ['android', 'ios']),
        throwsA(
          isA<KilnException>().having(
            (error) => error.code,
            'code',
            'prompt.invalid',
          ),
        ),
      );
    });
  });
}
