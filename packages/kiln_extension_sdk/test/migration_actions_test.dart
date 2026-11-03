import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationAction', () {
    test('parses every supported action', () {
      final rename = MigrationAction.fromMap(const {
        'type': 'rename_file',
        'from': 'a.dart',
        'to': 'b.dart',
      });
      final delete = MigrationAction.fromMap(const {
        'type': 'delete_file',
        'path': 'old.dart',
      });
      final dependency = MigrationAction.fromMap(const {
        'type': 'replace_dependency',
        'name': 'dio',
        'version': '^5.9.0',
      });
      final config = MigrationAction.fromMap(const {
        'type': 'update_config',
        'key': 'project.name',
        'value': 'renamed',
      });
      final message = MigrationAction.fromMap(const {
        'type': 'message',
        'text': 'Hello',
      });

      expect(rename, isA<RenameFileAction>());
      expect(delete, isA<DeleteFileAction>());
      expect(dependency, isA<ReplaceDependencyAction>());
      expect(config, isA<UpdateConfigAction>());
      expect(message, isA<MessageAction>());
    });

    test('round-trips to JSON', () {
      const action = RenameFileAction(from: 'a.dart', to: 'b.dart');

      expect(action.toJson(), {
        'type': 'rename_file',
        'from': 'a.dart',
        'to': 'b.dart',
      });
    });

    test('rejects an unknown action', () {
      expect(
        () => MigrationAction.fromMap(const {'type': 'explode'}),
        throwsA(isA<KilnException>()),
      );
    });
  });
}
