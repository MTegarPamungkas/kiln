// Live two-user RLS check for a local Supabase stack.
//
// Skipped unless the environment opts in, so generated apps and CI run the
// default suite offline:
//
//   KILN_SUPABASE_LOCAL_RLS=1
//   KILN_SUPABASE_LOCAL_URL=http://127.0.0.1:54321
//   KILN_SUPABASE_LOCAL_ANON_KEY=<anon or publishable key>
//
// The stack must contain the acceptance schema (owner-only `notes`, public-read
// `public_notes`). `tool/e2e/supabase_local_rls_probe.dart` documents it and
// prints the same matrix without a rendered app.
//
// This talks to GoTrue and PostgREST directly: the point is the server-side
// policy, which the SDK cannot fake. Email confirmation must be disabled on the
// stack (the local default) so `signup` returns a session.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final environment = Platform.environment;
  final url = environment['KILN_SUPABASE_LOCAL_URL'] ?? '';
  final anonKey = environment['KILN_SUPABASE_LOCAL_ANON_KEY'] ?? '';
  final enabled =
      environment['KILN_SUPABASE_LOCAL_RLS'] == '1' &&
      url.isNotEmpty &&
      anonKey.isNotEmpty;
  final skipReason = enabled
      ? null
      : 'Set KILN_SUPABASE_LOCAL_RLS=1, KILN_SUPABASE_LOCAL_URL and '
            'KILN_SUPABASE_LOCAL_ANON_KEY to run against a local stack.';

  group('local stack RLS', () {
    late _Stack stack;
    late _User alice;
    late _User bob;
    late String noteId;

    setUpAll(() async {
      if (!enabled) {
        return;
      }
      stack = _Stack(url, anonKey);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      alice = await stack.signUp('alice+$suffix@kiln.local', 'alice-pass-1');
      bob = await stack.signUp('bob+$suffix@kiln.local', 'bob-pass-1');
    });

    tearDownAll(() {
      if (!enabled) {
        return;
      }
      stack.close();
    });

    test('two users have distinct identities and tokens', () {
      expect(alice.userId, isNot(bob.userId));
      expect(alice.accessToken, isNot(bob.accessToken));
    }, skip: skipReason);

    test('owner reads own row, second user reads none', () async {
      final inserted = await stack.insert('notes', alice, {
        'body': 'alice private',
      });
      expect(inserted.status, 201);
      noteId = inserted.rows.single['id'].toString();
      expect(inserted.rows.single['user_id'], alice.userId);

      final own = await stack.select('notes', alice, 'id=eq.$noteId');
      expect(own.rows, hasLength(1));

      final other = await stack.select('notes', bob, 'id=eq.$noteId');
      expect(other.status, 200);
      expect(other.rows, isEmpty);
    }, skip: skipReason);

    test('second user cannot update, delete or forge owner', () async {
      final update = await stack.update('notes', bob, 'id=eq.$noteId', {
        'body': 'bob was here',
      });
      expect(update.rows, isEmpty);

      await stack.delete('notes', bob, 'id=eq.$noteId');
      final survived = await stack.select('notes', alice, 'id=eq.$noteId');
      expect(survived.rows, hasLength(1));
      expect(survived.rows.single['body'], 'alice private');

      final forged = await stack.insert('notes', bob, {
        'body': 'forged',
        'user_id': alice.userId,
      });
      expect(forged.status, greaterThanOrEqualTo(400));
    }, skip: skipReason);

    test('anonymous key reads no protected rows and cannot insert', () async {
      final read = await stack.select('notes', null, 'select=*');
      expect(read.status >= 400 || read.rows.isEmpty, isTrue);

      final insert = await stack.insert('notes', null, {'body': 'anon'});
      expect(insert.status, greaterThanOrEqualTo(400));
    }, skip: skipReason);

    test('public read policy is readable but not writable by others', () async {
      final inserted = await stack.insert('public_notes', alice, {
        'body': 'alice public',
      });
      expect(inserted.status, 201);
      final publicId = inserted.rows.single['id']!;

      final read = await stack.select(
        'public_notes',
        bob,
        'id=eq.$publicId',
      );
      expect(read.rows, hasLength(1));

      final update = await stack.update('public_notes', bob, 'id=eq.$publicId', {
        'body': 'bob rewrote it',
      });
      expect(update.rows, isEmpty);

      await stack.delete('public_notes', bob, 'id=eq.$publicId');
      final survived = await stack.select(
        'public_notes',
        alice,
        'id=eq.$publicId',
      );
      expect(survived.rows, hasLength(1));

      await stack.delete('notes', alice, 'id=eq.$noteId');
      final gone = await stack.select('notes', alice, 'id=eq.$noteId');
      expect(gone.rows, isEmpty);
    }, skip: skipReason);
  });
}

final class _User {
  const _User({
    required this.userId,
    required this.accessToken,
    required this.email,
  });

  final String userId;
  final String accessToken;
  final String email;
}

final class _Result {
  _Result(this.status, this.body);

  final int status;
  final String body;

  List<Map<String, Object?>> get rows {
    if (body.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(body);
    return decoded is List ? decoded.cast<Map<String, Object?>>() : const [];
  }
}

final class _Stack {
  _Stack(this.baseUrl, this.anonKey)
    : _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  final String baseUrl;
  final String anonKey;
  final HttpClient _client;

  void close() => _client.close(force: true);

  Future<_User> signUp(String email, String password) async {
    final result = await _request(
      'POST',
      '/auth/v1/signup',
      headers: {'apikey': anonKey},
      json: {'email': email, 'password': password},
    );
    final decoded = jsonDecode(result.body) as Map<String, Object?>;
    final token = decoded['access_token'] as String?;
    final user = decoded['user'] as Map<String, Object?>?;
    if (result.status != 200 || token == null || user == null) {
      throw StateError('sign up failed (${result.status}): ${result.body}');
    }
    return _User(
      userId: user['id']! as String,
      accessToken: token,
      email: email,
    );
  }

  Future<_Result> insert(
    String table,
    _User? user,
    Map<String, Object?> values,
  ) => _request(
    'POST',
    '/rest/v1/$table',
    user: user,
    headers: {'Prefer': 'return=representation'},
    json: values,
  );

  Future<_Result> select(String table, _User? user, String query) =>
      _request('GET', '/rest/v1/$table?$query', user: user);

  Future<_Result> update(
    String table,
    _User user,
    String query,
    Map<String, Object?> values,
  ) => _request(
    'PATCH',
    '/rest/v1/$table?$query',
    user: user,
    headers: {'Prefer': 'return=representation'},
    json: values,
  );

  Future<_Result> delete(String table, _User user, String query) =>
      _request('DELETE', '/rest/v1/$table?$query', user: user);

  Future<_Result> _request(
    String method,
    String path, {
    _User? user,
    Map<String, String> headers = const {},
    Map<String, Object?>? json,
  }) async {
    final request = await _client.openUrl(method, Uri.parse('$baseUrl$path'));
    request.headers.set('apikey', anonKey);
    request.headers.set('content-type', 'application/json');
    headers.forEach(request.headers.set);
    if (user != null) {
      request.headers.set('authorization', 'Bearer ${user.accessToken}');
    }
    if (json != null) {
      request.write(jsonEncode(json));
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Result(response.statusCode, body);
  }
}
