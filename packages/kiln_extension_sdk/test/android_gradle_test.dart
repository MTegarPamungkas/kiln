import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Android Gradle patches', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('sets minSdk and restores the original expression', () {
      const patch = AndroidGradleMinSdkPatch(24);

      patch.apply(files);
      var content = files.read('android/app/build.gradle.kts')!;
      expect(
        content,
        contains('minSdk = 24 // kiln:min_sdk from flutter.minSdkVersion'),
      );

      patch.revert(files);
      content = files.read('android/app/build.gradle.kts')!;
      expect(content, contains('minSdk = flutter.minSdkVersion'));
      expect(content, isNot(contains('kiln:min_sdk')));
    });

    test('is idempotent', () {
      const patch = AndroidGradleMinSdkPatch(24);
      patch.apply(files);
      patch.apply(files);

      expect(
        RegExp('kiln:min_sdk')
            .allMatches(files.read('android/app/build.gradle.kts')!),
        hasLength(1),
      );
    });

    test('raises compileSdk and restores the original expression', () {
      const patch = AndroidGradleCompileSdkPatch(37);

      patch.apply(files);
      var content = files.read('android/app/build.gradle.kts')!;
      expect(
        content,
        contains(
          'compileSdk = 37 // kiln:compile_sdk from flutter.compileSdkVersion',
        ),
      );

      patch.revert(files);
      content = files.read('android/app/build.gradle.kts')!;
      expect(content, contains('compileSdk = flutter.compileSdkVersion'));
      expect(content, isNot(contains('kiln:compile_sdk')));
    });

    test('never lowers an existing newer compileSdk', () {
      final path = 'android/app/build.gradle.kts';
      final content = files
          .read(path)!
          .replaceFirst(
            'compileSdk = flutter.compileSdkVersion',
            'compileSdk = 38',
          );
      files.write(path, content);

      const AndroidGradleCompileSdkPatch(37).apply(files);

      expect(files.read(path), contains('compileSdk = 38'));
      expect(files.read(path), isNot(contains('kiln:compile_sdk')));
    });

    test('switches MainActivity to FlutterFragmentActivity and back', () {
      const patch = AndroidActivityPatch('FlutterFragmentActivity');

      patch.apply(files);
      final path =
          'android/app/src/main/kotlin/com/example/fresh_app/MainActivity.kt';
      expect(files.read(path), contains('FlutterFragmentActivity'));
      expect(
        files.read(path),
        contains('import io.flutter.embedding.android.FlutterFragmentActivity'),
      );

      patch.revert(files);
      expect(files.read(path), contains(': FlutterActivity()'));
      expect(files.read(path), isNot(contains('FragmentActivity')));
    });

    test('enables core library desugaring and removes it on revert', () {
      const patch = AndroidGradleDesugaringPatch();

      patch.apply(files);
      var content = files.read('android/app/build.gradle.kts')!;
      expect(
        content,
        contains('isCoreLibraryDesugaringEnabled = true // kiln:desugar'),
      );
      expect(
        content,
        contains(
          'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5") '
          '// kiln:desugar',
        ),
      );

      patch.revert(files);
      content = files.read('android/app/build.gradle.kts')!;
      expect(content, isNot(contains('kiln:desugar')));
      expect(content, isNot(contains('desugar_jdk_libs')));
    });

    test('desugaring patch is idempotent', () {
      const patch = AndroidGradleDesugaringPatch();
      patch.apply(files);
      patch.apply(files);

      final content = files.read('android/app/build.gradle.kts')!;
      expect(RegExp('kiln:desugar').allMatches(content), hasLength(2));
    });
  });
}
