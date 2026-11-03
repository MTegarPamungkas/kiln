import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Contribution', () {
    test('is active when every condition is present', () {
      const contribution = Contribution(
        slot: 'http.interceptors',
        priority: 20,
        when: ['http_pipeline', 'connectivity'],
      );

      expect(contribution.isActive({'http_pipeline', 'connectivity'}), isTrue);
      expect(contribution.isActive({'http_pipeline'}), isFalse);
    });

    test('is active when it has no conditions', () {
      const contribution = Contribution(slot: 'app.wrappers');

      expect(contribution.isActive(<String>{}), isTrue);
    });

    test('parses YAML fields', () {
      final contribution = Contribution.fromMap(const <String, Object?>{
        'slot': 'http.interceptors',
        'item': 'HttpMiddleware',
        'priority': 30,
        'when': ['http_pipeline'],
      });

      expect(contribution.item, 'HttpMiddleware');
      expect(contribution.priority, 30);
      expect(contribution.toJson()['when'], ['http_pipeline']);
    });
  });
}
