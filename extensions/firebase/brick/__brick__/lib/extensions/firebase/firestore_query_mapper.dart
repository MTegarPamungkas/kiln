import 'package:kiln_core/kiln_core.dart';

import 'firestore_gateway.dart';

/// Translates a backend-neutral [RemoteQuery] into a Firestore query.
///
/// Firestore silently rejects some combinations at runtime because they need a
/// composite index. The mapper surfaces those as a validation [Failure] before
/// any network call so feature code gets an actionable message.
final class FirestoreQueryMapper {
  const FirestoreQueryMapper();

  static const int _maxDisjunctionValues = 30;

  FirestoreQuery map(RemoteQuery query) {
    final limit = query.limit;
    if (limit != null && limit <= 0) {
      throw _invalid('limit must be greater than 0.');
    }
    if (query.offset < 0) {
      throw _invalid('offset cannot be negative.');
    }

    final filters = <FirestoreFilter>[];
    for (final filter in query.filters) {
      filters.add(_mapFilter(filter));
    }
    final orders = _mapOrders(query.orderBy);
    _rejectCompositeIndexQueries(filters, orders);

    return FirestoreQuery(
      filters: List<FirestoreFilter>.unmodifiable(filters),
      orders: List<FirestoreOrder>.unmodifiable(orders),
      limit: limit,
      offset: query.offset,
    );
  }

  FirestoreFilter _mapFilter(RemoteFilter filter) {
    final field = filter.field.trim();
    if (field.isEmpty) {
      throw _invalid('The filter field cannot be empty.');
    }
    final value = filter.value;
    switch (filter.operator) {
      case RemoteFilterOperator.equals:
        if (value == null) {
          return FirestoreFilter(field, FirestoreFilterOperator.isNull);
        }
        return FirestoreFilter(field, FirestoreFilterOperator.equal, value);
      case RemoteFilterOperator.notEquals:
        if (value == null) {
          return FirestoreFilter(field, FirestoreFilterOperator.isNotNull);
        }
        return FirestoreFilter(field, FirestoreFilterOperator.notEqual, value);
      case RemoteFilterOperator.greaterThan:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.greaterThan,
          _requiredValue(filter),
        );
      case RemoteFilterOperator.greaterThanOrEqual:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.greaterThanOrEqual,
          _requiredValue(filter),
        );
      case RemoteFilterOperator.lessThan:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.lessThan,
          _requiredValue(filter),
        );
      case RemoteFilterOperator.lessThanOrEqual:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.lessThanOrEqual,
          _requiredValue(filter),
        );
      case RemoteFilterOperator.inList:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.inList,
          _disjunctionValues(filter),
        );
      case RemoteFilterOperator.notInList:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.notInList,
          _disjunctionValues(filter),
        );
      case RemoteFilterOperator.arrayContains:
        return FirestoreFilter(
          field,
          FirestoreFilterOperator.arrayContains,
          _requiredValue(filter),
        );
      case RemoteFilterOperator.isNull:
        return FirestoreFilter(field, FirestoreFilterOperator.isNull);
      case RemoteFilterOperator.isNotNull:
        return FirestoreFilter(field, FirestoreFilterOperator.isNotNull);
    }
  }

  List<FirestoreOrder> _mapOrders(List<RemoteOrder> orders) {
    final mapped = <FirestoreOrder>[];
    final fields = <String>{};
    for (final order in orders) {
      final field = order.field.trim();
      if (field.isEmpty) {
        throw _invalid('The orderBy field cannot be empty.');
      }
      if (!fields.add(field)) {
        throw _invalid('Field "$field" is sorted more than once.');
      }
      mapped.add(
        FirestoreOrder(
          field,
          descending: order.direction == RemoteSortDirection.descending,
        ),
      );
    }
    return mapped;
  }

  void _rejectCompositeIndexQueries(
    List<FirestoreFilter> filters,
    List<FirestoreOrder> orders,
  ) {
    if (orders.length > 1) {
      throw _unsupported(
        'Sorting by more than one field requires a Firestore '
        'composite index. Add that index, or use a native query.',
      );
    }

    final rangeFields = <String>{
      for (final filter in filters)
        if (_isRange(filter.operator)) filter.field,
    };
    if (rangeFields.length > 1) {
      throw _unsupported(
        'Range filters on multiple fields require a Firestore '
        'composite index.',
      );
    }
    if (rangeFields.isNotEmpty &&
        orders.isNotEmpty &&
        rangeFields.first != orders.first.field) {
      throw _unsupported(
        'A range filter and orderBy on different fields require a '
        'composite Firestore index.',
      );
    }

    final disjunctions = filters.where(
      (filter) =>
          filter.operator == FirestoreFilterOperator.inList ||
          filter.operator == FirestoreFilterOperator.notInList ||
          filter.operator == FirestoreFilterOperator.arrayContains,
    );
    if (disjunctions.length > 1) {
      throw _unsupported(
        'Firestore allows only one in, not-in, or '
        'array-contains filter per query.',
      );
    }
  }

  static bool _isRange(FirestoreFilterOperator operator) {
    switch (operator) {
      case FirestoreFilterOperator.notEqual:
      case FirestoreFilterOperator.greaterThan:
      case FirestoreFilterOperator.greaterThanOrEqual:
      case FirestoreFilterOperator.lessThan:
      case FirestoreFilterOperator.lessThanOrEqual:
      case FirestoreFilterOperator.notInList:
      case FirestoreFilterOperator.isNotNull:
        return true;
      case FirestoreFilterOperator.equal:
      case FirestoreFilterOperator.inList:
      case FirestoreFilterOperator.arrayContains:
      case FirestoreFilterOperator.isNull:
        return false;
    }
  }

  static Object _requiredValue(RemoteFilter filter) {
    final value = filter.value;
    if (value == null) {
      throw _invalid('The ${filter.operator.name} filter needs a value.');
    }
    return value;
  }

  static List<Object?> _disjunctionValues(RemoteFilter filter) {
    final value = filter.value;
    if (value is! Iterable) {
      throw _invalid(
        'The ${filter.operator.name} filter needs a list of values.',
      );
    }
    final values = <Object?>[];
    for (final item in value) {
      if (item == null) {
        throw _invalid('The filter value list cannot contain null.');
      }
      values.add(item);
    }
    if (values.isEmpty) {
      throw _invalid('The filter value list cannot be empty.');
    }
    if (values.length > _maxDisjunctionValues) {
      throw _invalid(
        'The ${filter.operator.name} filter allows at most '
        '$_maxDisjunctionValues values.',
      );
    }
    return List<Object?>.unmodifiable(values);
  }

  static Failure _invalid(String message) {
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: message,
      kind: FailureKind.validation,
    );
  }

  static Failure _unsupported(String message) {
    return Failure(
      code: FailureCode.validationUnsupportedValue,
      message: message,
      kind: FailureKind.validation,
    );
  }
}
