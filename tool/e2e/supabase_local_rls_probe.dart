// K04 local acceptance: two-user row level security against a local Supabase
// stack.
//
// The stack is disposable and local, so the probe creates its own users and
// notes. It needs no repository credentials; point it at any local stack:
//
//   supabase start            # inside the fixture directory
//   supabase status -o env    # ANON_KEY / API_URL
//   $env:KILN_SUPABASE_URL = 'http://127.0.0.1:54321'
//   $env:KILN_SUPABASE_ANON_KEY = '<anon or publishable key>'
//   dart run tool/e2e/supabase_local_rls_probe.dart
//
// What it proves, per assertion:
//   * a signed-in user only reads rows it owns (owner-only policy);
//   * a second user sees zero rows, cannot update or delete the first user's row;
//   * a user cannot insert a row for another user (WITH CHECK);
//   * an anonymous key cannot read the protected table at all;
//   * a table with a public read policy is readable by the other user while
//     still refusing their writes.

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final base = Platform.environment['KILN_SUPABASE_URL'] ?? '';
  final anonKey = Platform.environment['KILN_SUPABASE_ANON_KEY'] ?? '';
  if (base.isEmpty || anonKey.isEmpty) {
    stderr.writeln(
      'Set KILN_SUPABASE_URL and KILN_SUPABASE_ANON_KEY (see supabase status -o env).',
    );
    exitCode = 2;
    return;
  }

  final probe = _Probe(base, anonKey);
  try {
    await probe.run();
  } finally {
    probe.close();
  }
  if (probe.failures.isNotEmpty) {
    stderr.writeln('${probe.failures.length} assertion(s) failed');
    exitCode = 1;
  }
}

final class _Probe {
  _Probe(this.base, this.anonKey)
    : _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  final String base;
  final String anonKey;
  final HttpClient _client;
  final List<String> failures = <String>[];
  int _checks = 0;
  String get _runId =>
      DateTime.now().microsecondsSinceEpoch.toString().substring(6);

  void close() => _client.close(force: true);

  Future<void> run() async {
    final suffix = _runId;
    final alice = await _signUp('alice+$suffix@kiln.local', 'alice-password-1');
    final bob = await _signUp('bob+$suffix@kiln.local', 'bob-password-1');

    _expect('alice and bob are different users', alice.userId != bob.userId);

    final aNote = await _insert(
      'notes',
      alice,
      {'body': 'alice private note $suffix'},
    );
    _expect('alice inserts an owner-scoped note', aNote.status == 201);
    _expect(
      'the note is stamped with alice as owner',
      aNote.rows.length == 1 && aNote.rows.single['user_id'] == alice.userId,
      actual: '${aNote.rows}',
    );
    final noteId = aNote.rows.single['id'];

    final aliceReads = await _select('notes', alice, 'id=eq.$noteId');
    _expect('alice reads her own note', aliceReads.rows.length == 1);

    final bobReads = await _select('notes', bob, 'id=eq.$noteId');
    _expect(
      'bob reads zero rows from alice (RLS filters, not an error)',
      bobReads.status == 200 && bobReads.rows.isEmpty,
      actual: 'status=${bobReads.status} rows=${bobReads.rows}',
    );

    final bobUpdate = await _update('notes', bob, 'id=eq.$noteId', {
      'body': 'bob was here',
    });
    _expect(
      'bob cannot update alice note',
      bobUpdate.rows.isEmpty,
      actual: 'status=${bobUpdate.status} rows=${bobUpdate.rows}',
    );

    final bobDelete = await _delete('notes', bob, 'id=eq.$noteId');
    _expect(
      'bob delete affects zero rows',
      bobDelete.status == 204 || bobDelete.status == 200,
      actual: 'status=${bobDelete.status}',
    );

    final aliceStillThere = await _select('notes', alice, 'id=eq.$noteId');
    _expect(
      'alice note survived bob delete and still says alice',
      aliceStillThere.rows.length == 1 &&
          aliceStillThere.rows.single['body'] == 'alice private note $suffix',
      actual: '${aliceStillThere.rows}',
    );

    final forged = await _insert('notes', bob, {
      'body': 'forged owner',
      'user_id': alice.userId,
    });
    _expect(
      'bob cannot insert a note owned by alice (WITH CHECK)',
      forged.status >= 400,
      actual: 'status=${forged.status} body=${forged.raw}',
    );

    // Supabase grants table privileges to `anon` by default, so the refusal is
    // the policy itself: no policy applies to `anon`, hence no rows and no
    // write. Both a hard denial and an empty result satisfy "no data".
    final anonymous = await _select('notes', null, 'select=*');
    _expect(
      'anonymous key reads no protected rows',
      anonymous.status >= 400 || anonymous.rows.isEmpty,
      actual: 'status=${anonymous.status} body=${anonymous.raw}',
    );

    final anonymousInsert = await _insert('notes', null, {
      'body': 'anonymous note',
    });
    _expect(
      'anonymous insert is refused',
      anonymousInsert.status >= 400,
      actual: 'status=${anonymousInsert.status} body=${anonymousInsert.raw}',
    );

    final publicNote = await _insert('public_notes', alice, {
      'body': 'alice public note $suffix',
    });
    _expect('alice inserts a public-read note', publicNote.status == 201);
    final publicId = publicNote.rows.single['id'];

    final bobReadsPublic = await _select(
      'public_notes',
      bob,
      'id=eq.$publicId',
    );
    _expect(
      'bob reads alice public note (public read policy)',
      bobReadsPublic.rows.length == 1,
    );

    final bobWritesPublic = await _update(
      'public_notes',
      bob,
      'id=eq.$publicId',
      {'body': 'bob rewrote it'},
    );
    _expect(
      'bob cannot update alice public note',
      bobWritesPublic.rows.isEmpty,
      actual: 'status=${bobWritesPublic.status} rows=${bobWritesPublic.rows}',
    );

    final bobDeletesPublic = await _delete(
      'public_notes',
      bob,
      'id=eq.$publicId',
    );
    final publicSurvived = await _select(
      'public_notes',
      alice,
      'id=eq.$publicId',
    );
    _expect(
      'bob delete leaves alice public note intact',
      bobDeletesPublic.status < 400 && publicSurvived.rows.length == 1,
      actual:
          'delete=${bobDeletesPublic.status} remaining=${publicSurvived.rows}',
    );

    final aliceDeletes = await _delete('notes', alice, 'id=eq.$noteId');
    final gone = await _select('notes', alice, 'id=eq.$noteId');
    _expect(
      'alice deletes her own note',
      aliceDeletes.status < 400 && gone.rows.isEmpty,
      actual: 'delete=${aliceDeletes.status} remaining=${gone.rows}',
    );

    stdout.writeln(
      '$_checks checks, ${failures.length} failed'
      '${failures.isEmpty ? ' - RLS matrix holds' : ''}',
    );
    for (final failure in failures) {
      stdout.writeln('FAIL: $failure');
    }
  }

  void _expect(String label, bool ok, {String? actual}) {
    _checks += 1;
    if (ok) {
      stdout.writeln('ok   $label');
    } else {
      failures.add('$label${actual == null ? '' : ' ($actual)'}');
      stdout.writeln('FAIL $label${actual == null ? '' : ' ($actual)'}');
    }
  }

  Future<_User> _signUp(String email, String password) async {
    final response = await _request(
      'POST',
      '/auth/v1/signup',
      headers: {'apikey': anonKey},
      body: {'email': email, 'password': password},
    );
    final decoded = response.raw.isEmpty ? null : jsonDecode(response.raw);
    final payload = decoded is Map<String, Object?> ? decoded : null;
    final token = payload?['access_token'] as String?;
    final user = payload?['user'] as Map<String, Object?>?;
    if (response.status != 200 || token == null || user == null) {
      throw StateError(
        'sign up failed (${response.status}): ${response.raw}',
      );
    }
    return _User(
      userId: user['id'] as String,
      accessToken: token,
      email: email,
    );
  }

  Future<_Result> _insert(
    String table,
    _User? user,
    Map<String, Object?> values,
  ) => _request(
    'POST',
    '/rest/v1/$table',
    user: user,
    headers: {'Prefer': 'return=representation'},
    body: values,
  );

  Future<_Result> _select(String table, _User? user, String query) =>
      _request('GET', '/rest/v1/$table?$query', user: user);

  Future<_Result> _update(
    String table,
    _User user,
    String query,
    Map<String, Object?> values,
  ) => _request(
    'PATCH',
    '/rest/v1/$table?$query',
    user: user,
    headers: {'Prefer': 'return=representation'},
    body: values,
  );

  Future<_Result> _delete(String table, _User user, String query) =>
      _request('DELETE', '/rest/v1/$table?$query', user: user);

  Future<_Result> _request(
    String method,
    String path, {
    _User? user,
    Map<String, String> headers = const {},
    Map<String, Object?>? body,
  }) async {
    final request = await _client.openUrl(method, Uri.parse('$base$path'));
    request.headers.set('apikey', anonKey);
    request.headers.set('content-type', 'application/json');
    headers.forEach(request.headers.set);
    if (user != null) {
      request.headers.set('authorization', 'Bearer ${user.accessToken}');
    }
    if (body != null) {
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();
    return _Result(response.statusCode, raw);
  }
}

final class _User {
  _User({
    required this.userId,
    required this.accessToken,
    required this.email,
  });

  final String userId;
  final String accessToken;
  final String email;
}

final class _Result {
  _Result(this.status, this.raw);

  final int status;
  final String raw;

  List<Map<String, Object?>> get rows {
    if (raw.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    try {
      final value = jsonDecode(raw);
      if (value is List) {
        return value.cast<Map<String, Object?>>();
      }
    } on FormatException {
      return const <Map<String, Object?>>[];
    }
    return const <Map<String, Object?>>[];
  }
}
