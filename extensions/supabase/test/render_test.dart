import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('supabase brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const <String, Object?>{'name': 'supabase_app'},
      answers: const <String, Object?>{
        'url': 'https://demo.supabase.co',
        'anon_key': 'demo-anon-key',
        'schema': 'app',
      },
    );

    final paths = files.map((file) => file.relativePath).toList();
    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/supabase/supabase_module.dart',
        'lib/extensions/supabase/supabase_auth_repository.dart',
        'lib/extensions/supabase/supabase_client.dart',
        'lib/extensions/supabase/supabase_gateway.dart',
        'lib/extensions/supabase/supabase_failure_mapper.dart',
        'lib/extensions/supabase/supabase_config.dart',
        'lib/extensions/supabase/supabase_account_management.dart',
        'lib/extensions/supabase/supabase_token_provider.dart',
        'lib/extensions/supabase/supabase_session_bridge.dart',
        'lib/extensions/supabase/supabase_link_handler.dart',
        'lib/extensions/supabase/postgrest_gateway.dart',
        'lib/extensions/supabase/supabase_remote_database.dart',
        'lib/extensions/supabase/supabase_query_mapper.dart',
        'lib/extensions/supabase/supabase_realtime_gateway.dart',
        'lib/extensions/supabase/supabase_storage_gateway.dart',
        'lib/extensions/supabase/supabase_file_storage.dart',
        'test/extensions/supabase/supabase_auth_test.dart',
        'test/extensions/supabase/supabase_failure_mapper_test.dart',
        'test/extensions/supabase/supabase_module_test.dart',
        'test/extensions/supabase/supabase_config_test.dart',
        'test/extensions/supabase/supabase_account_management_test.dart',
        'test/extensions/supabase/supabase_token_provider_test.dart',
        'test/extensions/supabase/supabase_session_bridge_test.dart',
        'test/extensions/supabase/supabase_link_handler_test.dart',
        'test/extensions/supabase/supabase_remote_database_test.dart',
        'test/extensions/supabase/supabase_query_mapper_test.dart',
        'test/extensions/supabase/supabase_file_storage_test.dart',
        'test/extensions/supabase/supabase_contract_test.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('supabase_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("url: 'https://demo.supabase.co'"));
    expect(source, contains("anonKey: 'demo-anon-key'"));
    expect(source, contains("schema: 'app'"));

    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('supabase_module.dart'),
    );
    final moduleSource = String.fromCharCodes(module.bytes);
    expect(moduleSource, contains("'remote_database'"));
    expect(moduleSource, contains('SupabaseSessionBridge'));
  });

  test('answers replace the brick defaults without HTML escaping', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const <String, Object?>{'name': 'escaped_app'},
      answers: const <String, Object?>{
        'url': 'https://quoted.supabase.co',
        'anon_key': 'demo-anon-key',
        'schema': 'public',
      },
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('supabase_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("url: 'https://quoted.supabase.co'"));
    expect(source, isNot(contains('example.supabase.co')));
    expect(source, isNot(contains('&quot;')));
  });
}
