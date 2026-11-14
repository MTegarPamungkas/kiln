import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/appwrite_push_native/appwrite_push_native_transport.dart';

PushMessage _message(String payload) => PushMessage(
  topic: 'users/123',
  payload: Uint8List.fromList(utf8.encode(payload)),
  qos: 1,
);

void main() {
  test('maps the notification and data payload', () {
    final envelope = pushEnvelopeFromMessage(
      _message(
        jsonEncode(<String, Object?>{
          'notification': <String, Object?>{
            'title': 'Kiln',
            'body': 'Hello from Appwrite Push',
          },
          'data': <String, Object?>{'route': '/inbox', 'count': 2},
        }),
      ),
    );

    expect(envelope.title, 'Kiln');
    expect(envelope.body, 'Hello from Appwrite Push');
    expect(envelope.data, <String, Object?>{'route': '/inbox', 'count': 2});
  });

  test('tolerates non-JSON payloads', () {
    final envelope = pushEnvelopeFromMessage(_message('plain text'));

    expect(envelope.title, isNull);
    expect(envelope.body, isNull);
    expect(envelope.data, isEmpty);
  });

  test('treats empty title and body as absent', () {
    final envelope = pushEnvelopeFromMessage(
      _message(
        jsonEncode(<String, Object?>{
          'notification': <String, Object?>{'title': '', 'body': ''},
        }),
      ),
    );

    expect(envelope.title, isNull);
    expect(envelope.body, isNull);
  });
}
