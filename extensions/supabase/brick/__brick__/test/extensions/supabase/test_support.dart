import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:{{app_name}}/extensions/supabase/postgrest_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_config.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_realtime_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_storage_gateway.dart';

/// Fake auth gateway that mimics Supabase Auth behavior.
class FakeSupabaseGateway implements SupabaseGateway {
  FakeSupabaseGateway({this.initialSession});

  SupabaseSession? initialSession;
  SupabaseSession? _session;

  final StreamController<SupabaseSession?> _changes =
      StreamController<SupabaseSession?>.broadcast(sync: true);

  final List<String> signedInEmails = <String>[];
  final List<String> signedUpDisplayNames = <String>[];
  final List<String> resetEmails = <String>[];
  final List<Map<String, Object?>> updatedUsers = <Map<String, Object?>>[];
  final List<String> exchangedCodes = <String>[];
  final List<String> verifiedTokenHashes = <String>[];
  final List<String> verifiedTypes = <String>[];
  final List<String> oauthProviders = <String>[];
  final List<String?> oauthRedirects = <String?>[];
  final List<String> idTokenProviders = <String>[];

  String? lastEmailRedirect;
  String? lastVerificationRedirect;
  String? lastResetRedirect;
  bool forceRefreshRequested = false;
  int refreshUserCalls = 0;
  int signOutCalls = 0;
  bool cancelOAuth = false;
  bool requireEmailConfirmation = false;
  bool verifyOnSignIn = true;
  bool verifyOnRefresh = false;
  bool throwOnSignIn = false;

  @override
  SupabaseSession? get currentSession => _session;

  @override
  Stream<SupabaseSession?> get authStateChanges => _changes.stream;

  @override
  bool get isEmailVerified => _session?.emailVerified ?? false;

  @override
  Future<SupabaseSession?> restoreSession() async => initialSession;

  @override
  Future<SupabaseSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signedInEmails.add(email);
    if (throwOnSignIn || password == 'wrong-password') {
      throw const AuthException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );
    }
    return _emit(_sessionFor(email: email, displayName: 'Demo User'));
  }

  @override
  Future<SupabaseSession?> signUp({
    required String email,
    required String password,
    String? displayName,
    String? redirectTo,
  }) async {
    signedUpDisplayNames.add(displayName ?? '');
    lastEmailRedirect = redirectTo;
    if (requireEmailConfirmation) {
      return null;
    }
    return _emit(_sessionFor(email: email, displayName: displayName));
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    _session = null;
    _changes.add(null);
  }

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      forceRefreshRequested = true;
    }
    return _session?.accessToken;
  }

  @override
  Future<SupabaseSession> signInWithIdToken({
    required SocialProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    idTokenProviders.add(provider.name);
    return _emit(
      _sessionFor(email: 'social@kiln.dev', displayName: 'Social User'),
    );
  }

  @override
  Future<bool> signInWithOAuth({
    required SocialProvider provider,
    String? redirectTo,
    List<String> scopes = const <String>[],
  }) async {
    oauthProviders.add(provider.name);
    oauthRedirects.add(redirectTo);
    if (cancelOAuth) {
      return false;
    }
    _emit(_sessionFor(email: 'oauth@kiln.dev', displayName: 'OAuth User'));
    return true;
  }

  @override
  Future<SupabaseSession> exchangeCodeForSession(String code) async {
    exchangedCodes.add(code);
    return _emit(
      _sessionFor(email: 'callback@kiln.dev', displayName: 'Callback'),
    );
  }

  @override
  Future<SupabaseSession> verifyOtp({
    required String tokenHash,
    required String type,
  }) async {
    verifiedTokenHashes.add(tokenHash);
    verifiedTypes.add(type);
    return _emit(
      _sessionFor(email: 'verified@kiln.dev', displayName: 'Verified'),
    );
  }

  @override
  Future<void> refreshUser() async {
    refreshUserCalls += 1;
    final session = _session;
    if (verifyOnRefresh && session != null) {
      _emit(
        SupabaseSession(
          userId: session.userId,
          email: session.email,
          displayName: session.displayName,
          accessToken: session.accessToken,
          expiresAt: session.expiresAt,
          emailVerified: true,
          metadata: session.metadata,
        ),
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, {
    String? redirectTo,
  }) async {
    resetEmails.add(email);
    lastResetRedirect = redirectTo;
  }

  @override
  Future<void> sendEmailVerification({String? redirectTo}) async {
    lastVerificationRedirect = redirectTo;
  }

  @override
  Future<void> updateUser({
    String? email,
    String? password,
    Map<String, Object?>? data,
    String? redirectTo,
  }) async {
    updatedUsers.add(<String, Object?>{
      'email': ?email,
      'password': ?password,
      ...?data,
    });
    final session = _session;
    final displayName = data?['display_name'];
    if (session != null && displayName is String) {
      _emit(
        SupabaseSession(
          userId: session.userId,
          email: email ?? session.email,
          displayName: displayName,
          accessToken: session.accessToken,
          expiresAt: session.expiresAt,
          emailVerified: session.emailVerified,
          metadata: session.metadata,
        ),
      );
    }
  }

  SupabaseSession _sessionFor({required String email, String? displayName}) {
    return SupabaseSession(
      userId: 'user-1',
      email: email,
      displayName: displayName,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.utc(2030),
      emailVerified: verifyOnSignIn,
      metadata: <String, Object?>{'display_name': displayName},
    );
  }

  SupabaseSession _emit(SupabaseSession session) {
    _session = session;
    _changes.add(session);
    return session;
  }
}

/// One document change from the fake store.
final class FakeDocumentEvent {
  const FakeDocumentEvent(this.table, this.id, this.row);

  final String table;
  final String id;
  final Map<String, Object?>? row;
}

/// In-memory document store shared by the fake PostgREST and realtime.
final class FakeDocumentStore {
  final Map<String, Map<String, Map<String, Object?>>> tables =
      <String, Map<String, Map<String, Object?>>>{};
  final StreamController<FakeDocumentEvent> _events =
      StreamController<FakeDocumentEvent>.broadcast(sync: true);

  int _nextId = 0;

  Stream<FakeDocumentEvent> get events => _events.stream;

  Map<String, Object?> insert(String table, Map<String, Object?> data) {
    final id = data['id']?.toString() ?? 'doc-${++_nextId}';
    final row = <String, Object?>{...data, 'id': id};
    tables.putIfAbsent(table, () => <String, Map<String, Object?>>{})[id] = row;
    _events.add(FakeDocumentEvent(table, id, row));
    return row;
  }

  Map<String, Object?>? read(String table, String id) {
    return tables[table]?[id];
  }

  Map<String, Object?>? update(
    String table,
    String id,
    Map<String, Object?> data,
  ) {
    final existing = tables[table]?[id];
    if (existing == null) {
      return null;
    }
    final row = <String, Object?>{...existing, ...data, 'id': id};
    tables[table]![id] = row;
    _events.add(FakeDocumentEvent(table, id, row));
    return row;
  }

  bool delete(String table, String id) {
    final bucket = tables[table];
    if (bucket == null || !bucket.containsKey(id)) {
      return false;
    }
    bucket.remove(id);
    _events.add(FakeDocumentEvent(table, id, null));
    return true;
  }

  List<Map<String, Object?>> select(String table, PostgrestQuery? query) {
    var rows = tables[table]?.values.toList() ?? <Map<String, Object?>>[];
    for (final filter in query?.filters ?? const <PostgrestFilter>[]) {
      rows = rows.where((row) => _matches(row, filter)).toList();
    }
    for (final order in query?.orderBy ?? const <PostgrestOrder>[]) {
      rows.sort((left, right) {
        final result = _compare(left[order.column], right[order.column]);
        return order.ascending ? result : -result;
      });
    }
    final offset = query?.offset ?? 0;
    if (offset > 0) {
      rows = rows.skip(offset).toList();
    }
    final limit = query?.limit;
    if (limit != null && rows.length > limit) {
      rows = rows.take(limit).toList();
    }
    return rows;
  }

  bool _matches(Map<String, Object?> row, PostgrestFilter filter) {
    final actual = row[filter.column];
    final expected = filter.value;
    switch (filter.operator) {
      case PostgrestOperator.equals:
        return actual == expected;
      case PostgrestOperator.notEquals:
        return actual != expected;
      case PostgrestOperator.greaterThan:
        return _compare(actual, expected) > 0;
      case PostgrestOperator.greaterThanOrEqual:
        return _compare(actual, expected) >= 0;
      case PostgrestOperator.lessThan:
        return _compare(actual, expected) < 0;
      case PostgrestOperator.lessThanOrEqual:
        return _compare(actual, expected) <= 0;
      case PostgrestOperator.inList:
        return expected is Iterable && expected.contains(actual);
      case PostgrestOperator.notInList:
        return expected is Iterable && !expected.contains(actual);
      case PostgrestOperator.contains:
        if (actual is Iterable) {
          return actual.contains(expected);
        }
        return actual == expected;
      case PostgrestOperator.isNull:
        return actual == null;
      case PostgrestOperator.isNotNull:
        return actual != null;
    }
  }

  int _compare(Object? left, Object? right) {
    if (left is Comparable &&
        right != null &&
        left.runtimeType == right.runtimeType) {
      return left.compareTo(right);
    }
    return '$left'.compareTo('$right');
  }

  Future<void> dispose() => _events.close();
}

/// Fake PostgREST on top of [FakeDocumentStore].
class FakePostgrestGateway implements PostgrestGateway {
  FakePostgrestGateway({FakeDocumentStore? store})
    : store = store ?? FakeDocumentStore();

  final FakeDocumentStore store;
  PostgrestQuery? lastQuery;

  /// Error thrown by the next operation, consumed once.
  Object? failure;

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> data,
  ) async {
    _throwIfNeeded();
    return Map<String, Object?>.from(store.insert(table, data));
  }

  @override
  Future<Map<String, Object?>?> selectById(String table, String id) async {
    _throwIfNeeded();
    final row = store.read(table, id);
    return row == null ? null : Map<String, Object?>.from(row);
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    PostgrestQuery? query,
  }) async {
    _throwIfNeeded();
    lastQuery = query;
    return store
        .select(table, query)
        .map<Map<String, Object?>>((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }

  @override
  Future<Map<String, Object?>?> updateById(
    String table,
    String id,
    Map<String, Object?> data,
  ) async {
    _throwIfNeeded();
    final row = store.update(table, id, data);
    return row == null ? null : Map<String, Object?>.from(row);
  }

  @override
  Future<bool> deleteById(String table, String id) async {
    _throwIfNeeded();
    return store.delete(table, id);
  }

  void _throwIfNeeded() {
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
  }
}

/// Fake realtime that forwards [FakeDocumentStore] changes.
final class FakeSupabaseRealtimeGateway implements SupabaseRealtimeGateway {
  FakeSupabaseRealtimeGateway(this.store);

  final FakeDocumentStore store;
  int activeSubscriptions = 0;

  @override
  Stream<Map<String, Object?>?> watchRow(String table, String id) {
    final controller = StreamController<Map<String, Object?>?>();
    StreamSubscription<FakeDocumentEvent>? subscription;
    controller.onListen = () {
      activeSubscriptions += 1;
      subscription = store.events.listen((event) {
        if (event.table != table || event.id != id) {
          return;
        }
        controller.add(
          event.row == null ? null : Map<String, Object?>.from(event.row!),
        );
      });
    };
    controller.onCancel = () async {
      activeSubscriptions -= 1;
      await subscription?.cancel();
      subscription = null;
      await controller.close();
    };
    return controller.stream;
  }
}

/// In-memory fake Supabase Storage.
final class FakeSupabaseStorageGateway implements SupabaseStorageGateway {
  final Map<String, List<int>> files = <String, List<int>>{};
  final List<String> uploadedPaths = <String>[];
  final List<String> signedPaths = <String>[];
  final List<Duration> signedLifetimes = <Duration>[];
  final List<String> deletedPaths = <String>[];

  /// Error thrown by the next call, consumed once.
  Object? failure;

  @override
  Future<void> upload(
    String path,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata = const <String, String>{},
    bool upsert = false,
    ProgressCallback? onProgress,
  }) async {
    _throwIfNeeded();
    uploadedPaths.add(path);
    files[path] = List<int>.from(bytes);
    onProgress?.call(1);
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    _throwIfNeeded();
    final bytes = files[path];
    if (bytes == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'Berkas tidak ditemukan.',
        kind: FailureKind.storage,
      );
    }
    onProgress?.call(1);
    return List<int>.from(bytes);
  }

  @override
  Future<Uri> createSignedUrl(String path, Duration expiresIn) async {
    _throwIfNeeded();
    signedPaths.add(path);
    signedLifetimes.add(expiresIn);
    return Uri.parse(
      'https://storage.kiln.dev/$path?expires=${expiresIn.inSeconds}',
    );
  }

  @override
  Future<void> delete(String path) async {
    _throwIfNeeded();
    deletedPaths.add(path);
    if (files.remove(path) == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'Berkas tidak ditemukan.',
        kind: FailureKind.storage,
      );
    }
  }

  void _throwIfNeeded() {
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
  }
}

/// Test configuration without any network access.
SupabaseConfig testConfig() {
  return const SupabaseConfig(
    url: 'https://demo.supabase.co',
    anonKey: 'anon-key',
  );
}
