import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/widgets/avatar_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/widgets/image_source_sheet.dart';

import 'test_support.dart';

void main() {
  testWidgets('the source sheet returns the chosen source', (tester) async {
    late Future<MediaSource?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => result = ImageSourceSheet.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);

    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();
    expect(await result, MediaSource.camera);
  });

  testWidgets('the avatar picker sends the chosen image', (tester) async {
    const picked = PickedImage(
      path: '/tmp/avatar.png',
      name: 'avatar.png',
      bytes: tinyPng,
      mimeType: 'image/png',
      sizeBytes: 68,
    );
    final picker = FakeMediaPicker(result: picked);
    PickedImage? received;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarPicker(
            picker: picker,
            onPicked: (image) => received = image,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();

    expect(received, same(picked));
    expect(picker.sources, [MediaSource.gallery]);
  });

  testWidgets('the avatar picker shows a friendly failure', (tester) async {
    final picker = FakeMediaPicker(
      failure: const Failure(
        code: FailureCode.mediaUnavailable,
        message: 'Kamera tidak tersedia.',
        kind: FailureKind.media,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AvatarPicker(picker: picker)),
      ),
    );

    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();

    expect(find.text('Kamera tidak tersedia.'), findsOneWidget);
  });
}
