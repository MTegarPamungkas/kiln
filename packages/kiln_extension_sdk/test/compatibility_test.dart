import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Compatibility', () {
    const compatibility = Compatibility(
      kiln: '>=0.2.0 <0.3.0',
      dart: '>=3.9.0',
      flutter: '>=3.35.0',
    );

    test('accepts versions inside every range', () {
      expect(
        compatibility.isCompatible(
          kilnVersion: '0.2.4',
          dartVersion: '3.13.7',
          flutterVersion: '3.47.8',
        ),
        isTrue,
      );
    });

    test('reports each incompatible version', () {
      final problems = compatibility.problems(
        kilnVersion: '0.3.0',
        dartVersion: '3.8.0',
        flutterVersion: '3.20.0',
      );

      expect(problems, hasLength(3));
      expect(problems.join(), contains('kiln 0.3.0'));
      expect(problems.join(), contains('Dart 3.8.0'));
      expect(problems.join(), contains('Flutter 3.20.0'));
    });

    test('reports malformed constraints', () {
      const broken = Compatibility(kiln: 'not a range');

      expect(
        broken.problems(kilnVersion: '0.2.0').single,
        contains('malformed'),
      );
    });

    test('skips a check when the current version is unknown', () {
      expect(compatibility.problems(), isEmpty);
    });
  });
}
