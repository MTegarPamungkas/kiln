import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/storage/json_codec.dart';

void main() {
  test('encodes and decodes JSON values', () {
    const codec = JsonCodec();
    final encoded = codec.encode(<String, Object?>{'a': 1, 'b': true});

    expect(codec.decode(encoded), <String, Object?>{'a': 1, 'b': true});
  });
}
