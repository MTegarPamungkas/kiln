import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_auth_repository.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_file_storage.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_storage_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_remote_database.dart';

/// Shared fakes for the firebase brick tests.
///
/// The extension tree intentionally has no extra support file, so the fakes
/// live beside the contract suites and every test imports this library.
void main() {
  authRepositoryContract(
    description: 'FirebaseAuthRepository',
    create: () => FirebaseAuthRepository(gateway: FakeFirebaseAuthGateway()),
  );
  socialAuthContract(
    description: 'FirebaseSocialAuth',
    create: () => FirebaseSocialAuth(gateway: FakeFirebaseAuthGateway()),
  );
  remoteDatabaseContract(
    description: 'FirestoreRemoteDatabase',
    create: () => FirestoreRemoteDatabase(gateway: InMemoryFirestoreGateway()),
  );
  fileStorageContract(
    description: 'FirebaseFileStorage',
    create: () =>
        FirebaseFileStorage(gateway: InMemoryFirebaseStorageGateway()),
  );
}

/// Auth gateway that mimics Firebase Auth without touching the platform.
final class FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  FakeFirebaseAuthGateway({
    this.validEmail = 'user@kiln.dev',
    this.validPassword = 'password123',
  });

  final String validEmail;
  final String validPassword;

  final List<String> calls = <String>[];
  final List<bool> tokenRefreshes = <bool>[];
  final StreamController<FirebaseUser?> _changes =
      StreamController<FirebaseUser?>.broadcast(sync: true);

  FirebaseUser? _currentUser;
  Object? error;
  Object? socialError;
  bool providerReturnsNull = false;

  String? idTokenValue = 'id-token';
  bool emailVerified = false;
  String? lastEmulatorHost;
  int? lastEmulatorPort;
  int emulatorCalls = 0;

  @override
  FirebaseUser? get currentUser => _currentUser;

  @override
  Stream<FirebaseUser?> get authStateChanges => _changes.stream;

  /// Emits [user] to every auth listener.
  void emit(FirebaseUser? user) {
    _currentUser = user;
    _changes.add(user);
  }

  @override
  Future<FirebaseUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    calls.add('signIn:$email');
    _maybeThrow();
    if (email != validEmail || password != validPassword) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-credential',
        message: 'Invalid credentials',
      );
    }
    final user = FirebaseUser(
      uid: 'firebase-user',
      email: email,
      emailVerified: emailVerified,
    );
    emit(user);
    return user;
  }

  @override
  Future<FirebaseUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    calls.add('signUp:$email');
    _maybeThrow();
    final user = FirebaseUser(
      uid: 'firebase-user',
      email: email,
      displayName: displayName,
      emailVerified: emailVerified,
    );
    emit(user);
    return user;
  }

  @override
  Future<FirebaseSocialResult?> signInWithProvider(
    FirebaseSocialProvider provider,
  ) async {
    calls.add('provider:${provider.name}');
    _maybeThrow();
    final failure = socialError;
    if (failure != null) {
      throw failure;
    }
    if (providerReturnsNull) {
      return null;
    }
    final user = FirebaseUser(
      uid: 'social-${provider.name}',
      email: 'social@kiln.dev',
      displayName: 'Social User',
    );
    emit(user);
    return FirebaseSocialResult(
      user: user,
      idToken: 'social-id-token',
      accessToken: 'social-access-token',
    );
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _maybeThrow();
    emit(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    calls.add('reset:$email');
    _maybeThrow();
  }

  @override
  Future<void> sendEmailVerification() async {
    calls.add('sendEmailVerification');
    _maybeThrow();
  }

  @override
  Future<void> reloadUser() async {
    calls.add('reloadUser');
    _maybeThrow();
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {
    calls.add('displayName:$displayName');
    _maybeThrow();
    final user = _currentUser;
    if (user != null) {
      _currentUser = FirebaseUser(
        uid: user.uid,
        email: user.email,
        displayName: displayName,
        photoUrl: user.photoUrl,
        emailVerified: user.emailVerified,
        isAnonymous: user.isAnonymous,
      );
    }
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    calls.add('photoUrl:$photoUrl');
    _maybeThrow();
    final user = _currentUser;
    if (user != null) {
      _currentUser = FirebaseUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: photoUrl,
        emailVerified: user.emailVerified,
        isAnonymous: user.isAnonymous,
      );
    }
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    tokenRefreshes.add(forceRefresh);
    _maybeThrow();
    return idTokenValue;
  }

  @override
  Future<void> useEmulator(String host, int port) async {
    emulatorCalls += 1;
    lastEmulatorHost = host;
    lastEmulatorPort = port;
  }

  /// Closes the auth stream; call it at the end of a test.
  Future<void> dispose() => _changes.close();

  void _maybeThrow() {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }
}

/// Firestore gateway backed by a map, with the subset of query semantics the
/// contracts rely on.
final class InMemoryFirestoreGateway implements FirestoreGateway {
  final Map<String, Map<String, Map<String, Object?>>> collections =
      <String, Map<String, Map<String, Object?>>>{};
  final StreamController<_FirestoreChange> _changes =
      StreamController<_FirestoreChange>.broadcast(sync: true);
  final List<FirestoreQuery> queries = <FirestoreQuery>[];

  Object? error;
  String? emulatorHost;
  int? emulatorPort;
  int _counter = 0;

  Map<String, Map<String, Object?>> _collection(String name) {
    return collections.putIfAbsent(
      name,
      () => <String, Map<String, Object?>>{},
    );
  }

  FirestoreDocument? _document(String collection, String id) {
    final data = _collection(collection)[id];
    if (data == null) {
      return null;
    }
    return FirestoreDocument(id: id, data: Map<String, Object?>.of(data));
  }

  @override
  Future<FirestoreDocument> create(
    String collection,
    Map<String, Object?> data,
  ) async {
    _maybeThrow();
    final id = 'doc-${++_counter}';
    _collection(collection)[id] = Map<String, Object?>.of(data);
    _notify(collection, id);
    return FirestoreDocument(id: id, data: Map<String, Object?>.of(data));
  }

  @override
  Future<FirestoreDocument?> read(String collection, String id) async {
    _maybeThrow();
    return _document(collection, id);
  }

  @override
  Future<List<FirestoreDocument>> query(
    String collection,
    FirestoreQuery query,
  ) async {
    _maybeThrow();
    queries.add(query);
    var documents = <FirestoreDocument>[
      for (final entry in _collection(collection).entries)
        if (query.filters.every((filter) => _matches(entry.value, filter)))
          FirestoreDocument(
            id: entry.key,
            data: Map<String, Object?>.of(entry.value),
          ),
    ];
    for (final order in query.orders.reversed) {
      documents.sort((left, right) {
        final comparison = _compare(
          left.data[order.field],
          right.data[order.field],
        );
        return order.descending ? -comparison : comparison;
      });
    }
    if (query.offset > 0) {
      documents = documents.skip(query.offset).toList();
    }
    final limit = query.limit;
    if (limit != null) {
      documents = documents.take(limit).toList();
    }
    return documents;
  }

  @override
  Future<FirestoreDocument?> update(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    _maybeThrow();
    final existing = _collection(collection)[id];
    if (existing == null) {
      return null;
    }
    final merged = <String, Object?>{...existing, ...data};
    _collection(collection)[id] = merged;
    _notify(collection, id);
    return FirestoreDocument(id: id, data: Map<String, Object?>.of(merged));
  }

  @override
  Future<bool> delete(String collection, String id) async {
    _maybeThrow();
    if (_collection(collection).remove(id) == null) {
      return false;
    }
    _notify(collection, id);
    return true;
  }

  @override
  Stream<FirestoreDocument?> watch(String collection, String id) {
    late StreamController<FirestoreDocument?> controller;
    StreamSubscription<_FirestoreChange>? subscription;
    controller = StreamController<FirestoreDocument?>(
      sync: true,
      onListen: () {
        controller.add(_document(collection, id));
        subscription = _changes.stream
            .where(
              (change) => change.collection == collection && change.id == id,
            )
            .listen((_) => controller.add(_document(collection, id)));
      },
      onCancel: () {
        final active = subscription;
        subscription = null;
        return active?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  void useEmulator(String host, int port) {
    emulatorHost = host;
    emulatorPort = port;
  }

  /// Closes the change stream; call it at the end of a test.
  Future<void> dispose() => _changes.close();

  void _notify(String collection, String id) {
    _changes.add(_FirestoreChange(collection, id));
  }

  void _maybeThrow() {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }

  static bool _matches(Map<String, Object?> data, FirestoreFilter filter) {
    final value = data[filter.field];
    switch (filter.operator) {
      case FirestoreFilterOperator.equal:
        return value == filter.value;
      case FirestoreFilterOperator.notEqual:
        return value != filter.value;
      case FirestoreFilterOperator.greaterThan:
        return _compare(value, filter.value) > 0;
      case FirestoreFilterOperator.greaterThanOrEqual:
        return _compare(value, filter.value) >= 0;
      case FirestoreFilterOperator.lessThan:
        return _compare(value, filter.value) < 0;
      case FirestoreFilterOperator.lessThanOrEqual:
        return _compare(value, filter.value) <= 0;
      case FirestoreFilterOperator.inList:
        return _values(filter.value).contains(value);
      case FirestoreFilterOperator.notInList:
        return !_values(filter.value).contains(value);
      case FirestoreFilterOperator.arrayContains:
        final list = value;
        return list is List && list.contains(filter.value);
      case FirestoreFilterOperator.isNull:
        return value == null;
      case FirestoreFilterOperator.isNotNull:
        return value != null;
    }
  }

  static List<Object?> _values(Object? value) {
    return value is Iterable ? value.cast<Object?>().toList() : <Object?>[];
  }

  static int _compare(Object? left, Object? right) {
    if (left is num && right is num) {
      return left.compareTo(right);
    }
    if (left is String && right is String) {
      return left.compareTo(right);
    }
    return 0;
  }
}

final class _FirestoreChange {
  const _FirestoreChange(this.collection, this.id);

  final String collection;
  final String id;
}

/// Cloud Storage gateway backed by a map of byte lists.
final class InMemoryFirebaseStorageGateway implements FirebaseStorageGateway {
  final Map<String, List<int>> files = <String, List<int>>{};
  final List<String> deleted = <String>[];

  Object? error;
  String? emulatorHost;
  int? emulatorPort;

  @override
  Future<StoredFile> upload(
    FileUpload file, {
    ProgressCallback? onProgress,
  }) async {
    _maybeThrow();
    onProgress?.call(0.5);
    files[file.path] = List<int>.of(file.bytes);
    onProgress?.call(1);
    return StoredFile(
      path: file.path,
      url: 'https://storage.kiln.dev/${file.path}',
      size: file.bytes.length,
      contentType: file.contentType,
    );
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    _maybeThrow();
    final bytes = files[path];
    if (bytes == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'Berkas tidak ditemukan.',
        kind: FailureKind.file,
      );
    }
    onProgress?.call(1);
    return List<int>.of(bytes);
  }

  @override
  Future<Uri> url(String path) async {
    _maybeThrow();
    if (!files.containsKey(path)) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'Berkas tidak ditemukan.',
        kind: FailureKind.file,
      );
    }
    return Uri.parse('https://storage.kiln.dev/$path');
  }

  @override
  Future<void> delete(String path) async {
    _maybeThrow();
    if (files.remove(path) == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'Berkas tidak ditemukan.',
        kind: FailureKind.file,
      );
    }
    deleted.add(path);
  }

  @override
  Future<void> useEmulator(String host, int port) async {
    emulatorHost = host;
    emulatorPort = port;
  }

  void _maybeThrow() {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }
}
