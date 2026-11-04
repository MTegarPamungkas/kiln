import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'firebase_failure_mapper.dart';
import 'firestore_gateway.dart';
import 'firestore_query_mapper.dart';

/// [RemoteDatabase] backed by a [FirestoreGateway].
final class FirestoreRemoteDatabase implements RemoteDatabase {
  const FirestoreRemoteDatabase({
    required this.gateway,
    this.queryMapper = const FirestoreQueryMapper(),
    this.failureMapper = mapFirebaseError,
    this.idField = 'id',
  });

  final FirestoreGateway gateway;
  final FirestoreQueryMapper queryMapper;
  final FirebaseFailureMapper failureMapper;

  /// Document identifier added to every returned map.
  final String idField;

  @override
  Future<Map<String, Object?>> create(
    String collection,
    Map<String, Object?> data,
  ) async {
    _validateCollection(collection);
    try {
      final created = await gateway.create(collection, data);
      return _withId(created);
    } catch (error, stackTrace) {
      throw _mapCreateError(error, stackTrace);
    }
  }

  @override
  Future<Map<String, Object?>?> read(String collection, String id) async {
    _validateDocument(collection, id);
    try {
      final document = await gateway.read(collection, id);
      return document == null ? null : _withId(document);
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String collection, {
    RemoteQuery? query,
  }) async {
    _validateCollection(collection);
    final mapped = queryMapper.map(query ?? const RemoteQuery());
    try {
      final documents = await gateway.query(collection, mapped);
      return <Map<String, Object?>>[
        for (final document in documents) _withId(document),
      ];
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<Map<String, Object?>> update(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    _validateDocument(collection, id);
    try {
      final updated = await gateway.update(collection, id, data);
      if (updated == null) {
        throw _notFound(collection, id);
      }
      return _withId(updated);
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<void> delete(String collection, String id) async {
    _validateDocument(collection, id);
    try {
      final deleted = await gateway.delete(collection, id);
      if (!deleted) {
        throw _notFound(collection, id);
      }
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Stream<Map<String, Object?>?> watch(String collection, String id) {
    _validateDocument(collection, id);
    return gateway
        .watch(collection, id)
        .map<Map<String, Object?>?>(
          (document) => document == null ? null : _withId(document),
        )
        .transform(
          StreamTransformer<
            Map<String, Object?>?,
            Map<String, Object?>?
          >.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(failureMapper(error, stackTrace), stackTrace);
            },
          ),
        );
  }

  Map<String, Object?> _withId(FirestoreDocument document) {
    return <String, Object?>{...document.data, idField: document.id};
  }

  Failure _notFound(String collection, String id) {
    return Failure(
      code: FailureCode.remoteDatabaseNotFound,
      message: 'The document $collection/$id was not found.',
      kind: FailureKind.database,
    );
  }

  Failure _mapCreateError(Object error, StackTrace stackTrace) {
    final failure = failureMapper(error, stackTrace);
    if (failure.code == FailureCode.unexpected) {
      return Failure(
        code: FailureCode.remoteDatabaseUnavailable,
        message: 'Failed to create the document in Firestore.',
        kind: FailureKind.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return failure;
  }

  void _validateCollection(String collection) {
    if (collection.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The collection name cannot be empty.',
        kind: FailureKind.validation,
      );
    }
  }

  void _validateDocument(String collection, String id) {
    _validateCollection(collection);
    if (id.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The document id cannot be empty.',
        kind: FailureKind.validation,
      );
    }
  }
}
