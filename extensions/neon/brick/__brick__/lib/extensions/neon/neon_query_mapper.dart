import 'package:kiln_core/kiln_core.dart';

import 'neon_gateway.dart';

/// Maps a [RemoteQuery] to a PostgREST query for the Neon Data API.
///
/// | RemoteFilterOperator | PostgREST |
/// | --- | --- |
/// | equals | eq |
/// | notEquals | neq |
/// | greaterThan | gt |
/// | greaterThanOrEqual | gte |
/// | lessThan | lt |
/// | lessThanOrEqual | lte |
/// | inList | in |
/// | notInList | not.in |
/// | arrayContains | cs |
/// | isNull | is.null |
/// | isNotNull | not.is.null |
///
/// Combinations PostgREST cannot express throw
/// `Failure(validation.unsupported_value)`.
final class NeonQueryMapper {
  const NeonQueryMapper();

  static final RegExp _identifierPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static const Map<RemoteFilterOperator, PostgrestOperator> _operators =
      <RemoteFilterOperator, PostgrestOperator>{
        RemoteFilterOperator.equals: PostgrestOperator.equals,
        RemoteFilterOperator.notEquals: PostgrestOperator.notEquals,
        RemoteFilterOperator.greaterThan: PostgrestOperator.greaterThan,
        RemoteFilterOperator.greaterThanOrEqual:
            PostgrestOperator.greaterThanOrEqual,
        RemoteFilterOperator.lessThan: PostgrestOperator.lessThan,
        RemoteFilterOperator.lessThanOrEqual: PostgrestOperator.lessThanOrEqual,
        RemoteFilterOperator.inList: PostgrestOperator.inList,
        RemoteFilterOperator.notInList: PostgrestOperator.notInList,
        RemoteFilterOperator.arrayContains: PostgrestOperator.contains,
        RemoteFilterOperator.isNull: PostgrestOperator.isNull,
        RemoteFilterOperator.isNotNull: PostgrestOperator.isNotNull,
      };

  /// Maps [RemoteQuery]; null produces a query without filters.
  PostgrestQuery toPostgrest(RemoteQuery? query) {
    if (query == null) {
      return const PostgrestQuery();
    }
    return PostgrestQuery(
      filters: query.filters.map(_filter).toList(growable: false),
      orderBy: query.orderBy.map(_order).toList(growable: false),
      limit: _limit(query.limit),
      offset: _offset(query.offset),
    );
  }

  /// Checks a table or column name before it is used in a PostgREST URL.
  void validateIdentifier(String value, {String label = 'identifier'}) {
    if (!_identifierPattern.hasMatch(value)) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message:
            'The $label "$value" may only contain letters, digits, and underscores.',
        kind: FailureKind.validation,
      );
    }
  }

  PostgrestFilter _filter(RemoteFilter filter) {
    validateIdentifier(filter.field, label: 'column');
    final operator = _operators[filter.operator];
    if (operator == null) {
      throw Failure(
        code: FailureCode.validationUnsupportedValue,
        message:
            'Operator ${filter.operator.name} is not supported by PostgREST yet.',
        kind: FailureKind.validation,
        details: <String, Object?>{'field': filter.field},
      );
    }
    return PostgrestFilter(filter.field, operator, _value(filter, operator));
  }

  Object? _value(RemoteFilter filter, PostgrestOperator operator) {
    final value = filter.value;
    switch (operator) {
      case PostgrestOperator.isNull:
      case PostgrestOperator.isNotNull:
        if (value != null && value != true) {
          throw Failure(
            code: FailureCode.validationUnsupportedValue,
            message:
                'Filter ${filter.operator.name} on "${filter.field}" takes no value.',
            kind: FailureKind.validation,
          );
        }
        return null;
      case PostgrestOperator.inList:
      case PostgrestOperator.notInList:
        if (value is! Iterable<Object?> || value.isEmpty) {
          throw Failure(
            code: FailureCode.validationUnsupportedValue,
            message:
                'Filter ${filter.operator.name} on "${filter.field}" needs a non-empty list of values.',
            kind: FailureKind.validation,
          );
        }
        final values = value.map<Object?>(_scalar).toList(growable: false);
        if (values.contains(null)) {
          throw Failure(
            code: FailureCode.validationUnsupportedValue,
            message:
                'Filter ${filter.operator.name} on "${filter.field}" does not accept null values.',
            kind: FailureKind.validation,
          );
        }
        return values;
      case PostgrestOperator.contains:
        if (value == null) {
          throw Failure(
            code: FailureCode.validationUnsupportedValue,
            message: 'The contains filter on "${filter.field}" needs a value.',
            kind: FailureKind.validation,
          );
        }
        if (value is Iterable<Object?>) {
          return value.map<Object?>(_scalar).toList(growable: false);
        }
        return _scalar(value);
      case PostgrestOperator.greaterThan:
      case PostgrestOperator.greaterThanOrEqual:
      case PostgrestOperator.lessThan:
      case PostgrestOperator.lessThanOrEqual:
        if (value is bool || value == null) {
          throw Failure(
            code: FailureCode.validationUnsupportedValue,
            message:
                'Filter ${filter.operator.name} on "${filter.field}" needs a number, text, or date.',
            kind: FailureKind.validation,
          );
        }
        return _scalar(value);
      case PostgrestOperator.equals:
      case PostgrestOperator.notEquals:
        if (value == null) {
          throw Failure(
            code: FailureCode.validationUnsupportedValue,
            message:
                'Filter ${filter.operator.name} on "${filter.field}" needs a value; use isNull for null.',
            kind: FailureKind.validation,
          );
        }
        return _scalar(value);
    }
  }

  Object? _scalar(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Enum) {
      return value.name;
    }
    return value;
  }

  PostgrestOrder _order(RemoteOrder order) {
    validateIdentifier(order.field, label: 'column');
    return PostgrestOrder(
      order.field,
      ascending: order.direction == RemoteSortDirection.ascending,
    );
  }

  int? _limit(int? limit) {
    if (limit == null) {
      return null;
    }
    if (limit <= 0) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The row limit must be greater than zero.',
        kind: FailureKind.validation,
      );
    }
    return limit;
  }

  int _offset(int offset) {
    if (offset < 0) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The offset cannot be negative.',
        kind: FailureKind.validation,
      );
    }
    return offset;
  }
}
