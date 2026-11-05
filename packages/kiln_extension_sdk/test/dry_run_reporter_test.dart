import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('DryRunReport', () {
    const report = DryRunReport(
      files: [
        FileChange('lib/extensions/dio/dio_module.dart', FileChangeKind.create),
        FileChange('lib/app/app.dart', FileChangeKind.overwrite),
        FileChange('lib/app/edited.dart', FileChangeKind.conflict),
        FileChange('legacy/file.dart', FileChangeKind.skip),
        FileChange('old/file.dart', FileChangeKind.delete),
      ],
      patches: ['android.permission.INTERNET'],
      dependencies: {'dio': '^5.9.0'},
      devDependencies: {'json_serializable': '^6.8.0'},
      manualSteps: ['Run flutterfire configure'],
      warnings: ['A file was edited'],
    );

    test('detects conflicts', () {
      expect(report.hasConflicts, isTrue);
    });

    test('renders an aligned text report', () {
      final text = report.toText();

      expect(
        text,
        matches(RegExp(r'create\s+lib/extensions/dio/dio_module\.dart')),
      );
      expect(text, matches(RegExp(r'conflict\s+lib/app/edited\.dart')));
      expect(text, contains('patch      android.permission.INTERNET'));
      expect(text, contains('dio: ^5.9.0'));
      expect(text, contains('Run flutterfire configure'));
      expect(text, contains('warning    A file was edited'));
    });

    test('serializes to JSON for CI', () {
      final json = report.toJson();

      expect(json['has_conflicts'], isTrue);
      expect(json['files'], isA<List<Object?>>());
      expect((json['files']! as List<Object?>).first, {
        'path': 'lib/extensions/dio/dio_module.dart',
        'action': 'create',
      });
    });

    test('reports no conflicts for an empty plan', () {
      expect(const DryRunReport().hasConflicts, isFalse);
    });
  });
}
