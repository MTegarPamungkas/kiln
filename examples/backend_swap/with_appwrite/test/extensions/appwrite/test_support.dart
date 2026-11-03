import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_auth.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_database_gateway.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_file_storage.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_realtime_gateway.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_remote_database.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_session_bridge.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_storage_gateway.dart';

/// In-memory Appwrite account used by the extension tests.
final class FakeAppwriteAccount implements AppwriteAccount {
  FakeAppwriteAccount({
    this.validEmail = 'user@kiln.dev',
    this.validPassword = 'password123',
  }) {
    _accounts[validEmail] = (
      user: AppwriteAccountUser(id: 'user-1', email: validEmail),
      password: validPassword,
    );
  }

  final String validEmail;
  final String validPassword;
  final Map<String, ({AppwriteAccountUser user, String password})> _accounts =
      <String, ({AppwriteAccountUser user, String password})>{};
  final List<String> calls = <String>[];

  /// Forced failure for the next and later calls, if set.
  Object? failure;
  int createJwtCalls = 0;
  AppwriteAccountUser? _current;

  AppwriteAccountUser? get current => _current;

  void setCurrent(AppwriteAccountUser? user) {
    _current = user;
  }

  @override
  Future<AppwriteAccountUser?> currentUser() async {
    _throwIfConfigured();
    calls.add('currentUser');
    return _current;
  }

  @override
  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _throwIfConfigured();
    calls.add('signIn:$email');
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw AppwriteException(
        'Invalid credentials. Please check the email and password.',
        401,
        'user_invalid_credentials',
      );
    }
    _current = account.user;
    return AppwriteAuthResult(
      user: account.user,
      session: AppwriteAccountSession(
        id: 'session-1',
        userId: account.user.id,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      ),
    );
  }

  @override
  Future<AppwriteAccountUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _throwIfConfigured();
    calls.add('signUp:$email');
    if (_accounts.containsKey(email)) {
      throw AppwriteException('A user with the same email exists.', 409);
    }
    final user = AppwriteAccountUser(
      id: 'user-${_accounts.length + 1}',
      email: email,
      name: displayName ?? '',
    );
    _accounts[email] = (user: user, password: password);
    return user;
  }

  @override
  Future<void> signOut() async {
    _throwIfConfigured();
    calls.add('signOut');
    _current = null;
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectUrl,
  }) async {
    _throwIfConfigured();
    calls.add('reset:$email:$redirectUrl');
  }

  @override
  Future<void> sendEmailVerification({required String redirectUrl}) async {
    _throwIfConfigured();
    calls.add('verify:$redirectUrl');
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    _throwIfConfigured();
    calls.add('displayName:$displayName');
    final user = _current;
    if (user != null) {
      _current = user.copyWith(name: displayName);
    }
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    _throwIfConfigured();
    calls.add('photoUrl:$photoUrl');
    final user = _current;
    if (user == null) {
      return;
    }
    final prefs = Map<String, Object?>.from(user.prefs);
    if (photoUrl == null) {
      prefs.remove('photoUrl');
    } else {
      prefs['photoUrl'] = photoUrl;
    }
    _current = user.copyWith(prefs: prefs);
  }

  @override
  Future<String?> createJwt() async {
    _throwIfConfigured();
    createJwtCalls++;
    final user = _current;
    if (user == null) {
      throw AppwriteException(
        'User (role: guests) missing scope (account)',
        401,
        'general_unauthorized_scope',
      );
    }
    return 'jwt-${user.id}';
  }

  void _throwIfConfigured() {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }
}

/// Auth wired to a fake account and a fresh session bridge.
({AppwriteAuth auth, AppwriteSessionBridge bridge}) createFakeAuth({
  FakeAppwriteAccount? account,
  SessionController? controller,
  AppwriteTokenProvider? tokens,
}) {
  final effectiveAccount = account ?? FakeAppwriteAccount();
  final bridge = AppwriteSessionBridge(
    controller: controller,
    tokenProvider: tokens ?? AppwriteTokenProvider(account: effectiveAccount),
  );
  return (
    auth: AppwriteAuth(account: effectiveAccount, bridge: bridge),
    bridge: bridge,
  );
}

/// In-memory Appwrite database that evaluates the query strings it receives.
final class FakeAppwriteDatabaseGateway implements AppwriteDatabaseGateway {
  final Map<String, Map<String, Map<String, Object?>>> tables =
      <String, Map<String, Map<String, Object?>>>{};
  final List<String> calls = <String>[];

  /// Called after every write so a fake realtime gateway can broadcast it.
  void Function(String tableId, String rowId, Map<String, Object?>? document)?
  onChange;

  Object? failure;
  int _sequence = 0;

  @override
  Future<Map<String, Object?>> createRow(
    String tableId,
    Map<String, Object?> data,
  ) async {
    _throwIfConfigured();
    final id = 'row-${++_sequence}';
    final document = <String, Object?>{...data, 'id': id};
    tables.putIfAbsent(tableId, () => <String, Map<String, Object?>>{})[id] =
        document;
    calls.add('create:$tableId:$id');
    onChange?.call(tableId, id, document);
    return document;
  }

  @override
  Future<Map<String, Object?>?> getRow(String tableId, String rowId) async {
    _throwIfConfigured();
    calls.add('get:$tableId:$rowId');
    return tables[tableId]?[rowId];
  }

  @override
  Future<List<Map<String, Object?>>> listRows(
    String tableId, {
    List<String> queries = const <String>[],
  }) async {
    _throwIfConfigured();
    calls.add('list:$tableId:${queries.length}');
    final documents =
        tables[tableId]?.values.toList() ?? <Map<String, Object?>>[];
    return _applyQueries(documents, queries);
  }

  @override
  Future<Map<String, Object?>> updateRow(
    String tableId,
    String rowId,
    Map<String, Object?> data,
  ) async {
    _throwIfConfigured();
    final existing = tables[tableId]?[rowId];
    if (existing == null) {
      throw AppwriteException(
        'Document with the requested ID is not found.',
        404,
      );
    }
    final document = <String, Object?>{...existing, ...data, 'id': rowId};
    tables[tableId]![rowId] = document;
    calls.add('update:$tableId:$rowId');
    onChange?.call(tableId, rowId, document);
    return document;
  }

  @override
  Future<void> deleteRow(String tableId, String rowId) async {
    _throwIfConfigured();
    final removed = tables[tableId]?.remove(rowId);
    if (removed == null) {
      throw AppwriteException(
        'Document with the requested ID is not found.',
        404,
      );
    }
    calls.add('delete:$tableId:$rowId');
    onChange?.call(tableId, rowId, null);
  }

  void _throwIfConfigured() {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }

  List<Map<String, Object?>> _applyQueries(
    List<Map<String, Object?>> documents,
    List<String> queries,
  ) {
    var result = documents.toList();
    int? limit;
    var offset = 0;
    String? orderField;
    var descending = false;

    for (final query in queries) {
      final decoded = jsonDecode(query);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final method = '${decoded['method']}';
      final field = '${decoded['attribute'] ?? ''}';
      final values = decoded['values'];
      switch (method) {
        case 'equal':
          result = result.where((row) => _equal(row[field], values)).toList();
        case 'notEqual':
          result = result.where((row) => !_equal(row[field], values)).toList();
        case 'greaterThan':
          result = result
              .where((row) => _compare(row[field], _first(values)) > 0)
              .toList();
        case 'greaterThanEqual':
          result = result
              .where((row) => _compare(row[field], _first(values)) >= 0)
              .toList();
        case 'lessThan':
          result = result
              .where((row) => _compare(row[field], _first(values)) < 0)
              .toList();
        case 'lessThanEqual':
          result = result
              .where((row) => _compare(row[field], _first(values)) <= 0)
              .toList();
        case 'isNull':
          result = result.where((row) => row[field] == null).toList();
        case 'isNotNull':
          result = result.where((row) => row[field] != null).toList();
        case 'containsAny':
          result = result.where((row) {
            final stored = row[field];
            if (stored is! Iterable) {
              return false;
            }
            return _asList(values).any(stored.contains);
          }).toList();
        case 'orderAsc':
          orderField = field;
          descending = false;
        case 'orderDesc':
          orderField = field;
          descending = true;
        case 'limit':
          final value = _first(values);
          if (value is num) {
            limit = value.toInt();
          }
        case 'offset':
          final value = _first(values);
          if (value is num) {
            offset = value.toInt();
          }
      }
    }

    if (orderField != null) {
      result.sort((left, right) {
        final comparison = _compare(left[orderField], right[orderField]);
        return descending ? -comparison : comparison;
      });
    }
    if (offset > 0) {
      result = result.skip(offset).toList();
    }
    if (limit != null) {
      result = result.take(limit).toList();
    }
    return result;
  }

  bool _equal(Object? stored, Object? values) {
    final candidates = _asList(values);
    return candidates.any((candidate) => candidate == stored);
  }

  Object? _first(Object? values) {
    if (values is List && values.isNotEmpty) {
      return values.first;
    }
    return values;
  }

  List<Object?> _asList(Object? values) {
    if (values is List) {
      return values.cast<Object?>();
    }
    return <Object?>[values];
  }

  int _compare(Object? left, Object? right) {
    if (left is num && right is num) {
      return left.compareTo(right);
    }
    if (left is String && right is String) {
      return left.compareTo(right);
    }
    return 0;
  }
}

/// In-memory realtime gateway driven by the fake database.
final class FakeAppwriteRealtimeGateway implements AppwriteRealtimeGateway {
  FakeAppwriteRealtimeGateway({this.database});

  final AppwriteDatabaseGateway? database;
  final Map<String, StreamController<Map<String, Object?>?>> _watches =
      <String, StreamController<Map<String, Object?>?>>{};
  final Map<String, int> watchCalls = <String, int>{};
  bool disposed = false;

  @override
  Stream<Map<String, Object?>?> watch({
    required String tableId,
    required String rowId,
  }) {
    final key = '$tableId/$rowId';
    watchCalls[key] = (watchCalls[key] ?? 0) + 1;
    final controller = _watches.putIfAbsent(key, () {
      late final StreamController<Map<String, Object?>?> created;
      created = StreamController<Map<String, Object?>?>.broadcast(
        onListen: () async {
          final source = database;
          if (source == null) {
            return;
          }
          final document = await source.getRow(tableId, rowId);
          if (!created.isClosed) {
            created.add(document);
          }
        },
      );
      return created;
    });
    return controller.stream;
  }

  void emit({
    required String tableId,
    required String rowId,
    required Map<String, Object?>? document,
  }) {
    final controller = _watches['$tableId/$rowId'];
    if (controller != null && !controller.isClosed) {
      controller.add(document);
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    final controllers = _watches.values.toList(growable: false);
    _watches.clear();
    for (final controller in controllers) {
      await controller.close();
    }
  }
}

/// Database, gateway, and realtime wired together like the module does.
({
  AppwriteRemoteDatabase database,
  FakeAppwriteDatabaseGateway gateway,
  FakeAppwriteRealtimeGateway realtime,
})
createFakeRemoteDatabase() {
  final gateway = FakeAppwriteDatabaseGateway();
  final realtime = FakeAppwriteRealtimeGateway(database: gateway);
  gateway.onChange = (tableId, rowId, document) {
    realtime.emit(tableId: tableId, rowId: rowId, document: document);
  };
  return (
    database: AppwriteRemoteDatabase(gateway: gateway, realtime: realtime),
    gateway: gateway,
    realtime: realtime,
  );
}

/// In-memory Appwrite bucket used by the extension tests.
final class FakeAppwriteStorageGateway implements AppwriteStorageGateway {
  final Map<String, ({List<int> bytes, String? contentType})> files =
      <String, ({List<int> bytes, String? contentType})>{};
  final List<String> calls = <String>[];
  Object? failure;

  @override
  Future<StoredFile> upload({
    required String path,
    required List<int> bytes,
    String? contentType,
    ProgressCallback? onProgress,
  }) async {
    _throwIfConfigured();
    onProgress?.call(0.4);
    files[path] = (bytes: bytes, contentType: contentType);
    calls.add('upload:$path');
    onProgress?.call(1);
    return StoredFile(
      path: path,
      url: _urlFor(path).toString(),
      size: bytes.length,
      contentType: contentType,
    );
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    _throwIfConfigured();
    final stored = files[path];
    if (stored == null) {
      throw AppwriteException(
        'File with the requested ID could not be found.',
        404,
      );
    }
    calls.add('download:$path');
    onProgress?.call(1);
    return stored.bytes;
  }

  @override
  Future<Uri> url(String path) async {
    _throwIfConfigured();
    if (!files.containsKey(path)) {
      throw AppwriteException(
        'File with the requested ID could not be found.',
        404,
      );
    }
    calls.add('url:$path');
    return _urlFor(path);
  }

  @override
  Future<void> delete(String path) async {
    _throwIfConfigured();
    if (files.remove(path) == null) {
      throw AppwriteException(
        'File with the requested ID could not be found.',
        404,
      );
    }
    calls.add('delete:$path');
  }

  Uri _urlFor(String path) => Uri.parse('https://files.kiln.dev/$path');

  void _throwIfConfigured() {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }
}

/// FileStorage wired to a fake bucket.
AppwriteFileStorage createFakeFileStorage({
  FakeAppwriteStorageGateway? gateway,
}) {
  return AppwriteFileStorage(gateway: gateway ?? FakeAppwriteStorageGateway());
}

/// The 401 Appwrite returns when the current session is gone.
AppwriteException appwriteUnauthorizedFailure() {
  return AppwriteException(
    'User (role: guests) missing scope (account)',
    401,
    'general_unauthorized_scope',
  );
}
