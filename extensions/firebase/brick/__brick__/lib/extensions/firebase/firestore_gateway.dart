import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

/// Comparison supported by a [FirestoreFilter].
enum FirestoreFilterOperator {
  equal,
  notEqual,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inList,
  notInList,
  arrayContains,
  isNull,
  isNotNull,
}

/// One mapped filter, independent of the Firebase SDK.
final class FirestoreFilter {
  const FirestoreFilter(this.field, this.operator, [this.value]);

  final String field;
  final FirestoreFilterOperator operator;
  final Object? value;
}

/// One mapped sort clause.
final class FirestoreOrder {
  const FirestoreOrder(this.field, {this.descending = false});

  final String field;
  final bool descending;
}

/// A fully mapped Firestore query.
final class FirestoreQuery {
  const FirestoreQuery({
    this.filters = const <FirestoreFilter>[],
    this.orders = const <FirestoreOrder>[],
    this.limit,
    this.offset = 0,
  });

  final List<FirestoreFilter> filters;
  final List<FirestoreOrder> orders;
  final int? limit;
  final int offset;
}

/// A document together with its identifier.
final class FirestoreDocument {
  const FirestoreDocument({required this.id, required this.data});

  final String id;
  final Map<String, Object?> data;
}

/// Firestore access that can be faked without a Firebase app.
abstract interface class FirestoreGateway {
  Future<FirestoreDocument> create(
    String collection,
    Map<String, Object?> data,
  );

  Future<FirestoreDocument?> read(String collection, String id);

  Future<List<FirestoreDocument>> query(
    String collection,
    FirestoreQuery query,
  );

  /// Returns `null` when the document does not exist.
  Future<FirestoreDocument?> update(
    String collection,
    String id,
    Map<String, Object?> data,
  );

  /// Returns `false` when the document does not exist.
  Future<bool> delete(String collection, String id);

  Stream<FirestoreDocument?> watch(String collection, String id);

  void useEmulator(String host, int port);
}

/// [FirestoreGateway] backed by Cloud Firestore.
final class SdkFirestoreGateway implements FirestoreGateway {
  SdkFirestoreGateway({this.database});

  firestore.FirebaseFirestore? database;

  firestore.FirebaseFirestore get _instance =>
      database ??= firestore.FirebaseFirestore.instance;

  firestore.DocumentReference<Map<String, dynamic>> _document(
    String collection,
    String id,
  ) => _instance.collection(collection).doc(id);

  @override
  Future<FirestoreDocument> create(
    String collection,
    Map<String, Object?> data,
  ) async {
    final reference = _instance.collection(collection).doc();
    await reference.set(data);
    return FirestoreDocument(id: reference.id, data: data);
  }

  @override
  Future<FirestoreDocument?> read(String collection, String id) async {
    final snapshot = await _document(collection, id).get();
    return _snapshot(snapshot);
  }

  @override
  Future<List<FirestoreDocument>> query(
    String collection,
    FirestoreQuery query,
  ) async {
    var reference = _applyFilters(
      _instance.collection(collection),
      query.filters,
    );
    for (final order in query.orders) {
      reference = reference.orderBy(order.field, descending: order.descending);
    }

    var shaped = reference;
    if (query.offset > 0) {
      // Cloud Firestore no longer exposes Query.offset; page past the skipped
      // documents with a cursor instead. Both reads share the same filters and
      // ordering, and Firestore breaks ties by document id.
      final anchor = await reference.limit(query.offset).get();
      if (anchor.docs.length < query.offset) {
        return const <FirestoreDocument>[];
      }
      shaped = reference.startAfterDocument(anchor.docs.last);
    }
    final limit = query.limit;
    if (limit != null) {
      shaped = shaped.limit(limit);
    }
    final snapshot = await shaped.get();
    final documents = <FirestoreDocument>[];
    for (final document in snapshot.docs) {
      final mapped = _snapshot(document);
      if (mapped != null) {
        documents.add(mapped);
      }
    }
    return documents;
  }

  @override
  Future<FirestoreDocument?> update(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    final reference = _document(collection, id);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      return null;
    }
    await reference.update(data);
    return FirestoreDocument(
      id: id,
      data: <String, Object?>{...?snapshot.data(), ...data},
    );
  }

  @override
  Future<bool> delete(String collection, String id) async {
    final reference = _document(collection, id);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      return false;
    }
    await reference.delete();
    return true;
  }

  @override
  Stream<FirestoreDocument?> watch(String collection, String id) {
    return _document(collection, id).snapshots().map(_snapshot);
  }

  @override
  void useEmulator(String host, int port) {
    _instance.useFirestoreEmulator(host, port);
  }

  firestore.Query<Map<String, dynamic>> _applyFilters(
    firestore.Query<Map<String, dynamic>> reference,
    List<FirestoreFilter> filters,
  ) {
    var shaped = reference;
    for (final filter in filters) {
      final value = filter.value;
      shaped = switch (filter.operator) {
        FirestoreFilterOperator.equal => shaped.where(
          filter.field,
          isEqualTo: value,
        ),
        FirestoreFilterOperator.notEqual => shaped.where(
          filter.field,
          isNotEqualTo: value,
        ),
        FirestoreFilterOperator.greaterThan => shaped.where(
          filter.field,
          isGreaterThan: value,
        ),
        FirestoreFilterOperator.greaterThanOrEqual => shaped.where(
          filter.field,
          isGreaterThanOrEqualTo: value,
        ),
        FirestoreFilterOperator.lessThan => shaped.where(
          filter.field,
          isLessThan: value,
        ),
        FirestoreFilterOperator.lessThanOrEqual => shaped.where(
          filter.field,
          isLessThanOrEqualTo: value,
        ),
        FirestoreFilterOperator.inList => shaped.where(
          filter.field,
          whereIn: _values(value),
        ),
        FirestoreFilterOperator.notInList => shaped.where(
          filter.field,
          whereNotIn: _values(value),
        ),
        FirestoreFilterOperator.arrayContains => shaped.where(
          filter.field,
          arrayContains: value,
        ),
        FirestoreFilterOperator.isNull => shaped.where(
          filter.field,
          isNull: true,
        ),
        FirestoreFilterOperator.isNotNull => shaped.where(
          filter.field,
          isNull: false,
        ),
      };
    }
    return shaped;
  }

  static Iterable<Object?> _values(Object? value) {
    if (value is Iterable) {
      return value.cast<Object?>();
    }
    throw ArgumentError.value(value, 'value', 'Expected a list of values');
  }

  static FirestoreDocument? _snapshot(
    firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    return FirestoreDocument(
      id: snapshot.id,
      data: snapshot.data() ?? const <String, Object?>{},
    );
  }
}
