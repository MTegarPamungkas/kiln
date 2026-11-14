import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart' show createBundle;
import 'package:path/path.dart' as p;

/// Provisions a self-hosted Appwrite project for the extension's live e2e
/// suite and runs that suite inside a rendered fixture app.
///
/// ```
/// export KILN_APPWRITE_E2E=1
/// export KILN_APPWRITE_ENDPOINT=https://appwrite.example.com/v1
/// export KILN_APPWRITE_PROJECT=<project id>
/// export KILN_APPWRITE_API_KEY=<key with databases, storage, users scopes>
/// export KILN_APPWRITE_TEST_EMAIL=e2e@example.com
/// export KILN_APPWRITE_TEST_PASSWORD=password123
///
/// dart run tool/appwrite_e2e.dart provision   # create/clean server resources
/// dart run tool/appwrite_e2e.dart run         # render fixture + flutter test
/// ```
///
/// `provision` is idempotent: existing resources are updated, leftovers from
/// earlier runs (signup users, rows, files) are removed first. The API key is
/// only read here and never written to disk.
Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  switch (command) {
    case 'provision':
      await _provision();
    case 'run':
      await _run();
    case 'clean':
      await _provision(cleanOnly: true);
    case 'help':
    default:
      _printUsage();
      exit(command == 'help' ? 0 : 64);
  }
}

void _printUsage() {
  stderr.writeln('Usage: dart run tool/appwrite_e2e.dart <provision|run|clean>');
  stderr.writeln();
  stderr.writeln('Environment:');
  for (final line in const <String>[
    'KILN_APPWRITE_E2E=1                    opt-in for the live test suite',
    'KILN_APPWRITE_ENDPOINT=<url>           e.g. https://appwrite.example.com/v1',
    'KILN_APPWRITE_PROJECT=<id>             Appwrite project id',
    'KILN_APPWRITE_API_KEY=<key>            provisioning and cleanup; never stored',
    'KILN_APPWRITE_DATABASE=<id>            optional, default kiln',
    'KILN_APPWRITE_BUCKET=<id>              optional, default kiln_files',
    'KILN_APPWRITE_TEST_EMAIL=<email>       existing sign-in user',
    'KILN_APPWRITE_TEST_PASSWORD=<password> that user\'s password',
  ]) {
    stderr.writeln('  $line');
  }
}

Map<String, String> get _environment => Platform.environment;

String _requireEnv(String name) {
  final value = _environment[name];
  if (value == null || value.isEmpty) {
    stderr.writeln('Missing environment variable $name.');
    exit(64);
  }
  return value;
}

String get _endpoint => _requireEnv('KILN_APPWRITE_ENDPOINT');
String get _projectId => _requireEnv('KILN_APPWRITE_PROJECT');
String get _databaseId => _environment['KILN_APPWRITE_DATABASE'] ?? 'kiln';
String get _bucketId => _environment['KILN_APPWRITE_BUCKET'] ?? 'kiln_files';
String get _testEmail => _requireEnv('KILN_APPWRITE_TEST_EMAIL');
String get _testPassword => _requireEnv('KILN_APPWRITE_TEST_PASSWORD');

Uri _uri(
  String path, {
  Map<String, String>? params,
  List<String> pairs = const <String>[],
}) {
  // Join onto the endpoint instead of resolving an absolute path, which would
  // drop the endpoint's `/v1` segment.
  final base = Uri.parse(
    _endpoint.endsWith('/') ? _endpoint : '$_endpoint/',
  );
  final uri = base.resolveUri(
    Uri(path: path.startsWith('/') ? path.substring(1) : path),
  );
  final components = <String>[
    ...pairs,
    ...?params?.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}='
            '${Uri.encodeQueryComponent(entry.value)}'),
  ];
  return uri.replace(query: components.isEmpty ? null : components.join('&'));
}

/// Appwrite list endpoints take repeated `queries[]` params, each a JSON
/// object such as `{"method":"limit","values":[100]}`.
List<String> _queryPairs(int limit, int offset) => <String>[
      'queries[]=${Uri.encodeQueryComponent(jsonEncode(<String, Object?>{
        'method': 'limit',
        'values': <Object?>[limit],
      }))}',
      'queries[]=${Uri.encodeQueryComponent(jsonEncode(<String, Object?>{
        'method': 'offset',
        'values': <Object?>[offset],
      }))}',
    ];

final http.Client _client = http.Client();

Future<Map<String, Object?>> _send(
  String method,
  String path, {
  Map<String, String>? params,
  List<String> pairs = const <String>[],
  Object? body,
  String? apiKey,
}) async {
  final headers = <String, String>{
    'X-Appwrite-Project': _projectId,
    'Content-Type': 'application/json',
  };
  final key = apiKey ?? _environment['KILN_APPWRITE_API_KEY'];
  if (key != null && key.isNotEmpty) {
    headers['X-Appwrite-Key'] = key;
  }
  final request = http.Request(method, _uri(path, params: params, pairs: pairs))
    ..headers.addAll(headers);
  if (body != null) {
    request.body = jsonEncode(body);
  }
  final response = await http.Response.fromStream(await _client.send(request))
      .timeout(const Duration(seconds: 60));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw _ApiError(method, path, response.statusCode, response.body);
  }
  return response.body.isEmpty
      ? <String, Object?>{}
      : jsonDecode(response.body) as Map<String, Object?>;
}

final class _ApiError implements Exception {
  _ApiError(this.method, this.path, this.statusCode, this.body);

  final String method;
  final String path;
  final int statusCode;
  final String body;

  @override
  String toString() =>
      '$method $path failed with $statusCode: ${_shortBody(body)}';

  static String _shortBody(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, Object?> && json['message'] is String) {
        return json['message'] as String;
      }
    } on FormatException {
      // Keep the raw body.
    }
    return body.length > 300 ? '${body.substring(0, 300)}…' : body;
  }
}

Future<bool> _exists(String method, String path) async {
  try {
    await _send(method, path);
    return true;
  } on _ApiError catch (error) {
    if (error.statusCode == 404) {
      return false;
    }
    rethrow;
  }
}

Future<T> _poll<T>(
  Future<T> Function() action,
  bool Function(T) ready, {
  String description = '',
  Duration interval = const Duration(seconds: 2),
  Duration timeout = const Duration(seconds: 90),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final value = await action();
    if (ready(value)) {
      return value;
    }
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for $description');
    }
    await Future<void>.delayed(interval);
  }
}

// ---------------------------------------------------------------------------
// provision
// ---------------------------------------------------------------------------

Future<void> _provision({bool cleanOnly = false}) async {
  _requireEnv('KILN_APPWRITE_API_KEY');
  await _requireServer();

  await _cleanupLeftovers(withTestUser: true);

  if (cleanOnly) {
    stdout.writeln('Cleaned e2e leftovers. Done.');
    return;
  }

  await _ensureDatabase();
  await _ensureTable(
    tableId: 'users',
    name: 'E2E users',
    columns: const <_Column>[
      _Column.string(key: 'name', size: 256, required: true),
    ],
    indexes: const [_Index(key: 'name_name', columns: <String>['name'])],
  );
  await _ensureTable(
    tableId: 'tasks',
    name: 'E2E tasks',
    columns: const <_Column>[
      _Column.string(key: 'title', size: 256, required: true),
      _Column.boolean(key: 'done', required: true),
    ],
    indexes: const <_Index>[
      _Index(key: 'title_key', columns: <String>['title']),
      _Index(key: 'done_key', columns: <String>['done']),
    ],
  );
  await _ensureBucket();
  await _ensureTestUser();

  stdout.writeln();
  stdout.writeln('Provisioned. Next: dart run tool/appwrite_e2e.dart run');
}

Future<void> _requireServer() async {
  final health = await _send('GET', '/health');
  final status = health['status'];
  if (status != 'pass') {
    throw StateError('Appwrite health reports "$status".');
  }
  stdout.writeln('Server ${_uri('/health')} is healthy (project $_projectId).');
}

/// Removes users, rows, and files previous runs left behind so the contract
/// suites start from the same state every time. [withTestUser] also removes
/// the sign-in user; only [provision] passes it because that is the command
/// which recreates the user with the configured password.
Future<void> _cleanupLeftovers({bool withTestUser = false}) async {
  stdout.writeln('Cleaning leftovers from earlier runs…');

  final emails = <String>[
    if (withTestUser) _testEmail,
    'new@kiln.dev',
  ];
  for (final email in emails) {
    final userId = await _findUserIdByEmail(email);
    if (userId != null) {
      await _send('DELETE', '/users/$userId');
      stdout.writeln('  deleted user $email');
    }
  }
  final stale = await _listAllPages<String>(
    (pairs) => _send('GET', '/users', pairs: pairs),
    'users',
    (user) => user[r'$id'] as String,
    where: (user) =>
        ((user['email'] as String?) ?? '').startsWith('e2e-signup-'),
  );
  for (final userId in stale) {
    await _send('DELETE', '/users/$userId');
    stdout.writeln('  deleted signup user $userId');
  }

  if (await _exists('GET', '/databases/$_databaseId')) {
    for (final tableId in const <String>['users', 'tasks']) {
      // A first run has no tables yet; skip the row cleanup then.
      if (!await _exists('GET', '/tablesdb/$_databaseId/tables/$tableId')) {
        continue;
      }
      final removed = await _deleteAllRows(tableId);
      if (removed > 0) {
        stdout.writeln('  deleted $removed row(s) from $tableId');
      }
    }
  }

  if (await _exists('GET', '/storage/buckets/$_bucketId')) {
    final removed = await _deleteAllBucketFiles();
    if (removed > 0) {
      stdout.writeln('  deleted $removed file(s) from $_bucketId');
    }
  }
}

Future<String?> _findUserIdByEmail(String email) async {
  final result = await _send('GET', '/users', params: {'search': email});
  final users = result['users'] as List<Object?>? ?? const <Object?>[];
  for (final user in users) {
    final map = user as Map<String, Object?>;
    if (map['email'] == email) {
      return map[r'$id'] as String;
    }
  }
  return null;
}

/// Walks a paginated list endpoint, optionally keeping only matching entries.
Future<List<TValue>> _listAllPages<TValue>(
  Future<Map<String, Object?>> Function(List<String> queryPairs) fetch,
  String listKey,
  TValue Function(Map<String, Object?> map) valueOf, {
  bool Function(Map<String, Object?> map)? where,
}) async {
  final values = <TValue>[];
  var offset = 0;
  while (true) {
    final page = await fetch(_queryPairs(100, offset));
    final items = page[listKey] as List<Object?>? ?? const <Object?>[];
    for (final item in items) {
      final map = item as Map<String, Object?>;
      if (where == null || where(map)) {
        values.add(valueOf(map));
      }
    }
    final total = (page['total'] as num?)?.toInt() ?? 0;
    offset += items.length;
    if (offset >= total || items.isEmpty) {
      return values;
    }
  }
}

Future<int> _deleteAllRows(String tableId) async {
  final rows = await _listAllPages<String>(
    (pairs) => _send(
      'GET',
      '/tablesdb/$_databaseId/tables/$tableId/rows',
      pairs: pairs,
    ),
    'rows',
    (row) => row[r'$id'] as String,
  );
  for (final rowId in rows) {
    await _send('DELETE', '/tablesdb/$_databaseId/tables/$tableId/rows/$rowId');
  }
  return rows.length;
}

Future<int> _deleteAllBucketFiles() async {
  final files = await _listAllPages<String>(
    (pairs) => _send('GET', '/storage/buckets/$_bucketId/files', pairs: pairs),
    'files',
    (file) => file[r'$id'] as String,
  );
  for (final fileId in files) {
    await _send('DELETE', '/storage/buckets/$_bucketId/files/$fileId');
  }
  return files.length;
}

Future<void> _ensureDatabase() async {
  if (await _exists('GET', '/databases/$_databaseId')) {
    stdout.writeln('Database $_databaseId exists.');
    return;
  }
  await _send('POST', '/databases', body: <String, Object?>{
    'databaseId': _databaseId,
    'name': 'Kiln e2e',
  });
  stdout.writeln('Created database $_databaseId.');
}

final class _Column {
  const _Column.string({
    required this.key,
    required this.size,
    required this.required,
  }) : type = 'string';

  const _Column.boolean({required this.key, required this.required})
      : type = 'boolean',
        size = null;

  final String key;
  final String type;
  final bool required;
  final int? size;
}

final class _Index {
  const _Index({required this.key, required this.columns});

  final String key;
  final List<String> columns;
}

Future<void> _ensureTable({
  required String tableId,
  required String name,
  required List<_Column> columns,
  required List<_Index> indexes,
}) async {
  final path = '/tablesdb/$_databaseId/tables/$tableId';
  final permissions = <String>[
    'create("users")',
    'read("users")',
    'update("users")',
    'delete("users")',
  ];
  if (await _exists('GET', path)) {
    await _send('PUT', path, body: <String, Object?>{
      'permissions': permissions,
      'rowSecurity': false,
      'enabled': true,
    });
    stdout.writeln('Table $tableId exists; permissions refreshed.');
  } else {
    await _send('POST', '/tablesdb/$_databaseId/tables', body: <String, Object?>{
      'tableId': tableId,
      'name': name,
      'permissions': permissions,
      'rowSecurity': false,
      'enabled': true,
    });
    stdout.writeln('Created table $tableId.');
  }

  for (final column in columns) {
    final columnPath = '$path/columns/${column.key}';
    if (await _exists('GET', columnPath)) {
      continue;
    }
    // Required columns cannot declare a default, so none is sent.
    await _send('POST', '$path/columns/${column.type}', body: <String, Object?>{
      'key': column.key,
      'required': column.required,
      if (column.size != null) 'size': column.size,
    });
    stdout.writeln('  created column ${column.key} (${column.type}).');
  }

  for (final index in indexes) {
    final indexPath = '$path/indexes/${index.key}';
    if (await _exists('GET', indexPath)) {
      continue;
    }
    await _send('POST', '$path/indexes', body: <String, Object?>{
      'key': index.key,
      'type': 'key',
      'columns': index.columns,
    });
    stdout.writeln('  created index ${index.key}.');
  }

  // Schema changes are processed asynchronously; queries fail while the
  // columns or indexes are still building.
  await _poll(
    () => _send('GET', path),
    (table) => _tableReady(table, columns, indexes),
    description: 'table $tableId schema to become available',
  );
}

bool _tableReady(
  Map<String, Object?> table,
  List<_Column> columns,
  List<_Index> indexes,
) {
  final tableColumns = table['columns'] as List<Object?>? ?? const <Object?>[];
  final tableIndexes = table['indexes'] as List<Object?>? ?? const <Object?>[];
  for (final column in columns) {
    final found = tableColumns
        .cast<Map<String, Object?>?>()
        .any((entry) => entry?['key'] == column.key);
    if (!found) {
      return false;
    }
  }
  for (final index in indexes) {
    final found = tableIndexes
        .cast<Map<String, Object?>?>()
        .where((entry) => entry?['key'] == index.key)
        .any((entry) => entry?['status'] == 'available');
    if (!found) {
      return false;
    }
  }
  return true;
}

Future<void> _ensureBucket() async {
  final path = '/storage/buckets/$_bucketId';
  final permissions = <String>[
    'create("users")',
    'read("users")',
    'update("users")',
    'delete("users")',
  ];
  if (await _exists('GET', path)) {
    await _send('PUT', path, body: <String, Object?>{
      'name': 'Kiln e2e files',
      'permissions': permissions,
      'fileSecurity': false,
      'enabled': true,
    });
    stdout.writeln('Bucket $_bucketId exists; permissions refreshed.');
    return;
  }
  await _send('POST', '/storage/buckets', body: <String, Object?>{
    'bucketId': _bucketId,
    'name': 'Kiln e2e files',
    'permissions': permissions,
    'fileSecurity': false,
    'enabled': true,
  });
  stdout.writeln('Created bucket $_bucketId.');
}

Future<void> _ensureTestUser() async {
  final existingId = await _findUserIdByEmail(_testEmail);
  if (existingId != null) {
    await _send('DELETE', '/users/$existingId');
  }
  final userId = 'e2e-user';
  try {
    await _send('POST', '/users', body: <String, Object?>{
      'userId': userId,
      'email': _testEmail,
      'password': _testPassword,
      'name': 'Kiln e2e user',
    });
  } on _ApiError catch (error) {
    if (error.statusCode == 409) {
      // The id lingers when a same-id user exists under another email.
      await _send('POST', '/users', body: <String, Object?>{
        'userId': 'e2e-user-${DateTime.now().millisecondsSinceEpoch}',
        'email': _testEmail,
        'password': _testPassword,
        'name': 'Kiln e2e user',
      });
    } else {
      rethrow;
    }
  }
  stdout.writeln('Created test user $_testEmail.');
}

// ---------------------------------------------------------------------------
// run
// ---------------------------------------------------------------------------

Future<void> _run() async {
  // Fail fast on missing opt-in variables before spending minutes on pub get.
  _requireEnv('KILN_APPWRITE_TEST_EMAIL');
  _requireEnv('KILN_APPWRITE_TEST_PASSWORD');
  // Leftover rows and files from earlier runs would break the contract
  // assertions, so every run starts from a clean state.
  _requireEnv('KILN_APPWRITE_API_KEY');
  await _requireServer();
  await _cleanupLeftovers(withTestUser: false);

  final repoRoot = Directory(p.join(Directory.current.path)).parent.path;
  final toolDir = Directory(p.join(Directory.current.path, 'tool'));
  final root = toolDir.existsSync() &&
          File(p.join(toolDir.path, 'appwrite_e2e.dart')).existsSync()
      ? Directory.current.path
      : repoRoot;

  final fixture = Directory(p.join(root, 'e2e_appwrite'));
  await _renderFixture(fixture, root);

  stdout.writeln('Running flutter pub get…');
  await _process('flutter', const ['pub', 'get'], fixture);

  stdout.writeln('Running live e2e suite…');
  await _process('flutter', const [
    'test',
    'test/extensions/appwrite/appwrite_e2e_test.dart',
  ], fixture);
}

Future<void> _renderFixture(Directory fixture, String root) async {
  final brick = Directory(
    p.join(root, 'extensions', 'appwrite', 'brick'),
  );
  final files = await const BrickRenderer().render(
    bundle: createBundle(brick),
    vars: <String, dynamic>{
      'id': 'appwrite',
      'app_name': 'e2e_appwrite',
      'endpoint': _endpoint,
      'project_id': _projectId,
      'database_id': _databaseId,
      'bucket_id': _bucketId,
    },
  );
  for (final file in files) {
    final target = File(p.join(fixture.path, file.relativePath));
    await target.parent.create(recursive: true);
    await target.writeAsBytes(file.bytes);
  }

  final corePath = p.join(root, 'packages', 'kiln_core').replaceAll('\\', '/');
  final testingPath =
      p.join(root, 'packages', 'kiln_testing').replaceAll('\\', '/');
  await File(p.join(fixture.path, 'pubspec.yaml')).writeAsString('''
name: e2e_appwrite
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  appwrite: ^28.2.0
  http: ^1.6.0
  shared_preferences: ^2.3.0
  kiln_core:
    path: $corePath
dev_dependencies:
  flutter_test:
    sdk: flutter
  kiln_testing:
    path: $testingPath
dependency_overrides:
  kiln_core:
    path: $corePath
  kiln_testing:
    path: $testingPath
''');
  stdout.writeln('Rendered fixture into ${fixture.path}.');
}

Future<void> _process(
  String executable,
  List<String> arguments,
  Directory workingDirectory,
) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
    runInShell: Platform.isWindows,
    environment: _environment,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
