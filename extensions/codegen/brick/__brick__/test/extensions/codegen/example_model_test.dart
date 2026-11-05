import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/codegen/example/example_model.dart';

void main() {
  group('ExampleModel', () {
    test('serializes with snake_case keys and epoch dates', () {
      final model = ExampleModel(
        id: 'a',
        itemCount: 2,
        createdAt: DateTime.utc(2021, 6, 1),
        link: Uri.parse('https://x.test/p'),
      );

      final json = model.toJson();

      expect(json['item_count'], 2);
      expect(json['created_at'], isA<int>());
    });

    test('round trips through fromJson', () {
      final model = ExampleModel(
        id: 'a',
        itemCount: 2,
        createdAt: DateTime.utc(2021, 6, 1),
        link: Uri.parse('https://x.test/p'),
      );

      final restored = ExampleModel.fromJson(model.toJson());

      expect(restored.id, 'a');
      expect(restored.itemCount, 2);
      expect(restored.createdAt?.toUtc(), DateTime.utc(2021, 6, 1));
      expect(restored.link?.host, 'x.test');
    });

    test('freezed equality and copyWith work', () {
      final model = ExampleModel(id: 'a', itemCount: 1);

      expect(model.copyWith(itemCount: 2).itemCount, 2);
      expect(model, ExampleModel(id: 'a', itemCount: 1));
    });
  });
}
