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

    test('selectMany keeps the shown selection on an empty answer', () async {
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => '',
        write: (_) {},
      );

      expect(
        await prompter.selectMany(
          'Platforms:',
          ['android', 'ios', 'web'],
          defaults: {'android', 'web'},
        ),
        <String>['android', 'web'],
      );
    });

    test('selectMany toggles entries by number', () async {
      final answers = <String?>['1 3', '2,2'];
      var index = 0;
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => answers[index++],
        write: (_) {},
      );

      expect(
        await prompter.selectMany(
          'Platforms:',
          ['android', 'ios', 'web'],
          defaults: {'ios'},
        ),
        <String>['android', 'ios', 'web'],
      );
      expect(
        await prompter.selectMany('Platforms:', ['android', 'ios', 'web']),
        <String>[],
      );
    });

    test('selectMany falls back to defaults without interaction', () async {
      final quiet = Prompter(interactive: false);
      expect(
        await quiet.selectMany(
          'Platforms:',
          ['android', 'ios'],
          defaults: {'ios'},
        ),
        <String>['ios'],
      );
      final assumed = Prompter(assumeYes: true, interactive: false);
      expect(
        await assumed.selectMany(
          'Platforms:',
          ['android', 'ios'],
          defaults: {'android'},
        ),
        <String>['android'],
      );
    });

    test('selectMany rejects a number outside the options', () async {
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => '9',
        write: (_) {},
      );

      await expectLater(
        prompter.selectMany('Platforms:', ['android', 'ios']),
        throwsA(
          isA<KilnException>().having(
            (error) => error.code,
            'code',
            'prompt.invalid',
          ),
        ),
      );
    });

    test('selectMany navigates with arrows and toggles with space', () async {
      final session = _ScriptedRawKeys(<RawKeyPress>[
        const RawKeyPress(RawKey.down),
        const RawKeyPress(RawKey.space),
        const RawKeyPress(RawKey.down),
        const RawKeyPress(RawKey.space),
        const RawKeyPress(RawKey.enter),
      ]);
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => null,
        write: (_) {},
        rawKeys: session,
      );

      expect(
        await prompter.selectMany('Pick:', ['a', 'b', 'c']),
        <String>['b', 'c'],
      );
      expect(session.restoreCount, 1);
    });

    test('selectMany cancels on escape in raw mode', () async {
      final session = _ScriptedRawKeys(<RawKeyPress>[const RawKeyPress(RawKey.cancel)]);
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => null,
        write: (_) {},
        rawKeys: session,
      );

      await expectLater(
        prompter.selectMany('Pick:', ['a', 'b']),
        throwsA(
          isA<KilnException>().having(
            (error) => error.code,
            'code',
            'prompt.cancelled',
          ),
        ),
      );
      expect(session.restoreCount, 1);
    });

    test('selectMany jumps and toggles with a digit', () async {
      final session = _ScriptedRawKeys(
        <RawKeyPress>[const RawKeyPress(RawKey.digit, digit: 3)],
      );
      final prompter = Prompter(
        interactive: true,
        readLine: (_) => null,
        write: (_) {},
        rawKeys: session,
      );

      expect(
        await prompter.selectMany('Pick:', ['a', 'b', 'c']),
        <String>['c'],
      );
    });
  });
}

final class _ScriptedRawKeys implements RawKeySource {
  _ScriptedRawKeys(this.keys);

  final List<RawKeyPress> keys;
  int restoreCount = 0;

  @override
  RawModeSession? enter() {
    var index = 0;
    return _ScriptedSession(() {
      if (index >= keys.length) {
        return const RawKeyPress(RawKey.enter);
      }
      return keys[index++];
    }, () {
      restoreCount++;
    });
  }
}

final class _ScriptedSession implements RawModeSession {
  _ScriptedSession(this.nextKey, this.onRestore);

  final RawKeyPress Function() nextKey;
  final void Function() onRestore;

  @override
  Future<RawKeyPress> read() async => nextKey();

  @override
  void restore() {
    onRestore();
  }
}
