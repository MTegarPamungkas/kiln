// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'supabase_failure_mapper.dart';

/// PostgREST filter operators used by the extension.
enum PostgrestOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inList,
  notInList,
  contains,
  isNull,
  isNotNull,
}

/// One PostgREST condition ready to be applied to a query builder.
final class PostgrestFilter {
  const PostgrestFilter(this.column, this.operator, [this.value]);

  final String column;
  final PostgrestOperator operator;
  final Object? value;

  @override
  String toString() => 'PostgrestFilter($column, ${operator.name}, $value)';
}

/// One PostgREST ordering clause.
final class PostgrestOrder {
  const PostgrestOrder(this.column, {this.ascending = true});

  final String column;
  final bool ascending;

  @override
  String toString() => 'PostgrestOrder($column, ascending: $ascending)';
}

/// PostgREST query produced by mapping a [RemoteQuery].
final class PostgrestQuery {
  const PostgrestQuery({
    this.filters = const <PostgrestFilter>[],
    this.orderBy = const <PostgrestOrder>[],
    this.limit,
    this.offset = 0,
  });

  final List<PostgrestFilter> filters;
  final List<PostgrestOrder> orderBy;
  final int? limit;
  final int offset;
}

/// PostgREST operations used by [SupabaseRemoteDatabase], wrapped so they
/// can be faked in tests.
abstract interface class PostgrestGateway {
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> data);

  Future<Map<String, Object?>?> selectById(String table, String id);

  Future<List<Map<String, Object?>>> select(
    String table, {
    PostgrestQuery? query,
  });

  /// Null when no row with [id] exists.
  Future<Map<String, Object?>?> updateById(
    String table,
    String id,
    Map<String, Object?> data,
  );

  /// False when no row with [id] exists.
  Future<bool> deleteById(String table, String id);
}

/// [PostgrestGateway] backed by the Supabase client.
final class SdkPostgrestGateway implements PostgrestGateway {
  SdkPostgrestGateway({required SupabaseClientProvider provider})
    : _provider = provider;

  static const int _offsetPageSize = 1000;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> data,
  ) async {
    try {
      final row = await _client.from(table).insert(data).select().single();
      return Map<String, Object?>.from(row);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.remoteDatabaseUnavailable);
    }
  }

  @override
  Future<Map<String, Object?>?> selectById(String table, String id) async {
    try {
      final row = await _client.from(table).select().eq('id', id).maybeSingle();
      return row == null ? null : Map<String, Object?>.from(row);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.remoteDatabaseQueryFailed);
    }
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    PostgrestQuery? query,
  }) async {
    try {
      var filters = _client.from(table).select();
      for (final filter in query?.filters ?? const <PostgrestFilter>[]) {
        filters = _apply(filters, filter);
      }
      PostgrestTransformBuilder<PostgrestList> builder = filters;
      for (final order in query?.orderBy ?? const <PostgrestOrder>[]) {
        builder = builder.order(order.column, ascending: order.ascending);
      }
      final limit = query?.limit;
      if (limit != null) {
        builder = builder.limit(limit);
      }
      final offset = query?.offset ?? 0;
      if (offset > 0) {
        builder = builder.range(
          offset,
          offset + (limit ?? _offsetPageSize) - 1,
        );
      }
      final rows = await builder;
      return rows
          .map<Map<String, Object?>>((row) => Map<String, Object?>.from(row))
          .toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.remoteDatabaseQueryFailed);
    }
  }

  @override
  Future<Map<String, Object?>?> updateById(
    String table,
    String id,
    Map<String, Object?> data,
  ) async {
    try {
      final row = await _client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();
      return row == null ? null : Map<String, Object?>.from(row);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.remoteDatabaseUnavailable);
    }
  }

  @override
  Future<bool> deleteById(String table, String id) async {
    try {
      final row = await _client
          .from(table)
          .delete()
          .eq('id', id)
          .select()
          .maybeSingle();
      return row != null;
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.remoteDatabaseUnavailable);
    }
  }

  PostgrestFilterBuilder<PostgrestList> _apply(
    PostgrestFilterBuilder<PostgrestList> builder,
    PostgrestFilter filter,
  ) {
    switch (filter.operator) {
      case PostgrestOperator.equals:
        return builder.eq(filter.column, _requiredValue(filter));
      case PostgrestOperator.notEquals:
        return builder.neq(filter.column, _requiredValue(filter));
      case PostgrestOperator.greaterThan:
        return builder.gt(filter.column, _requiredValue(filter));
      case PostgrestOperator.greaterThanOrEqual:
        return builder.gte(filter.column, _requiredValue(filter));
      case PostgrestOperator.lessThan:
        return builder.lt(filter.column, _requiredValue(filter));
      case PostgrestOperator.lessThanOrEqual:
        return builder.lte(filter.column, _requiredValue(filter));
      case PostgrestOperator.inList:
        return builder.inFilter(filter.column, _values(filter));
      case PostgrestOperator.notInList:
        return builder.not(filter.column, 'in', _values(filter));
      case PostgrestOperator.contains:
        return builder.contains(filter.column, _requiredValue(filter));
      case PostgrestOperator.isNull:
        return builder.isFilter(filter.column, null);
      case PostgrestOperator.isNotNull:
        return builder.not(filter.column, 'is', null);
    }
  }

  List<Object?> _values(PostgrestFilter filter) {
    final value = filter.value;
    if (value is! Iterable) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message:
            'Filter ${filter.operator.name} pada "${filter.column}" butuh daftar nilai.',
        kind: FailureKind.validation,
      );
    }
    return value.toList(growable: false);
  }

  Object _requiredValue(PostgrestFilter filter) {
    final value = filter.value;
    if (value == null) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message:
            'Filter ${filter.operator.name} pada "${filter.column}" butuh nilai.',
        kind: FailureKind.validation,
      );
    }
    return value;
  }

  Failure _map(Object error, StackTrace stackTrace, FailureCode fallbackCode) {
    return mapSupabaseError(
      error,
      stackTrace: stackTrace,
      fallbackCode: fallbackCode,
      fallbackKind: FailureKind.database,
    );
  }
}
