import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('PromptSpec', () {
    test('validates URLs', () {
      const prompt = PromptSpec(name: 'base_url', type: PromptType.url);

      expect(prompt.validate('https://api.kiln.dev').isValid, isTrue);
      expect(prompt.validate('ftp://api.kiln.dev').isValid, isFalse);
      expect(prompt.validate('not a url').isValid, isFalse);
    });

    test('validates integers with a range', () {
      const prompt = PromptSpec(
        name: 'timeout',
        type: PromptType.intValue,
        min: 1,
        max: 120,
      );

      expect(prompt.validate(15).value, 15);
      expect(prompt.validate('30').value, 30);
      expect(prompt.validate(0).isValid, isFalse);
      expect(prompt.validate(121).isValid, isFalse);
      expect(prompt.validate('abc').isValid, isFalse);
    });

    test('validates booleans', () {
      const prompt = PromptSpec(name: 'enabled', type: PromptType.boolValue);

      expect(prompt.validate(true).value, isTrue);
      expect(prompt.validate('false').value, isFalse);
      expect(prompt.validate('yes').isValid, isFalse);
    });

    test('validates enum and multi values', () {
      const single = PromptSpec(
        name: 'mode',
        type: PromptType.enumValue,
        options: ['light', 'dark'],
      );
      const multi = PromptSpec(
        name: 'kinds',
        type: PromptType.multi,
        options: ['camera', 'photos'],
        required: true,
      );

      expect(single.validate('dark').isValid, isTrue);
      expect(single.validate('sepia').isValid, isFalse);
      expect(multi.validate(['camera', 'photos']).value, ['camera', 'photos']);
      expect(multi.validate(['microphone']).isValid, isFalse);
      expect(multi.validate(<String>[]).isValid, isFalse);
    });

    test('required values use the default and reject missing input', () {
      const prompt = PromptSpec(
        name: 'api_key',
        type: PromptType.secret,
        required: true,
      );
      const withDefault = PromptSpec(
        name: 'interval',
        type: PromptType.intValue,
        required: true,
        defaultValue: 30,
      );

      expect(prompt.validate(null).isValid, isFalse);
      expect(withDefault.validate(null).value, 30);
    });

    test('parses the YAML prompt type names', () {
      final prompt = PromptSpec.fromMap(const <String, Object?>{
        'name': 'connect_timeout',
        'type': 'int',
        'default': 15,
        'min': 1,
        'max': 120,
      });

      expect(prompt.type, PromptType.intValue);
      expect(prompt.defaultValue, 15);
      expect(prompt.toJson()['type'], 'int');
    });

    test('rejects an unknown prompt type', () {
      expect(
        () => PromptSpec.fromMap(const <String, Object?>{
          'name': 'bad',
          'type': 'date',
        }),
        throwsA(isA<KilnException>()),
      );
    });
  });
}
