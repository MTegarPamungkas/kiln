import 'package:appwrite/appwrite.dart';
import 'package:kiln_core/kiln_core.dart';

/// Translates a [RemoteQuery] into Appwrite query strings.
///
/// A null value with [RemoteFilterOperator.equals] becomes `isNull`, and
/// `inList`/`notInList` reuse Appwrite's list form of `equal`/`notEqual`.
final class AppwriteQueryMapper {
  const AppwriteQueryMapper();

  List<String> map(RemoteQuery? query) {
    if (query == null) {
      return const <String>[];
    }
    final queries = <String>[];
    for (final filter in query.filters) {
      queries.add(_filter(filter));
    }
    for (final order in query.orderBy) {
      final field = order.field.trim();
      if (field.isEmpty) {
        throw _invalid('A RemoteOrder field must not be empty.');
      }
      queries.add(
        order.direction == RemoteSortDirection.ascending
            ? Query.orderAsc(field)
            : Query.orderDesc(field),
      );
    }
    final limit = query.limit;
    if (limit != null) {
      if (limit <= 0) {
        throw _invalid('RemoteQuery.limit must be greater than zero.');
      }
      queries.add(Query.limit(limit));
    }
    if (query.offset < 0) {
      throw _invalid('RemoteQuery.offset must not be negative.');
    }
    if (query.offset > 0) {
      queries.add(Query.offset(query.offset));
    }
    return List<String>.unmodifiable(queries);
  }

  String _filter(RemoteFilter filter) {
    final field = filter.field.trim();
    if (field.isEmpty) {
      throw _invalid('A RemoteFilter field must not be empty.');
    }
    final value = filter.value;
    return switch (filter.operator) {
      RemoteFilterOperator.equals =>
        value == null ? Query.isNull(field) : Query.equal(field, value),
      RemoteFilterOperator.notEquals =>
        value == null ? Query.isNotNull(field) : Query.notEqual(field, value),
      RemoteFilterOperator.greaterThan => Query.greaterThan(
        field,
        _required(filter),
      ),
      RemoteFilterOperator.greaterThanOrEqual => Query.greaterThanEqual(
        field,
        _required(filter),
      ),
      RemoteFilterOperator.lessThan => Query.lessThan(field, _required(filter)),
      RemoteFilterOperator.lessThanOrEqual => Query.lessThanEqual(
        field,
        _required(filter),
      ),
      RemoteFilterOperator.inList => Query.equal(field, _list(filter)),
      RemoteFilterOperator.notInList => Query.notEqual(field, _list(filter)),
      RemoteFilterOperator.arrayContains => Query.containsAny(field, <Object?>[
        _required(filter),
      ]),
      RemoteFilterOperator.isNull => Query.isNull(field),
      RemoteFilterOperator.isNotNull => Query.isNotNull(field),
    };
  }

  Object _required(RemoteFilter filter) {
    final value = filter.value;
    if (value == null) {
      throw _invalid(
        'RemoteFilter ${filter.operator.name} on "${filter.field}" '
        'requires a value.',
      );
    }
    return value;
  }

  List<Object?> _list(RemoteFilter filter) {
    final value = filter.value;
    if (value is! Iterable) {
      throw _invalid(
        'RemoteFilter ${filter.operator.name} on "${filter.field}" '
        'requires a list value.',
      );
    }
    final values = value.map<Object?>((entry) => entry).toList(growable: false);
    if (values.isEmpty) {
      throw _invalid(
        'RemoteFilter ${filter.operator.name} on "${filter.field}" '
        'requires at least one value.',
      );
    }
    return values;
  }

  Failure _invalid(String message) {
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: message,
      kind: FailureKind.validation,
    );
  }
}
