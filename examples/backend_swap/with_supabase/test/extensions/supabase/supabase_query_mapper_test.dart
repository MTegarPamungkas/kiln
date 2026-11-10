import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_supabase/extensions/supabase/postgrest_gateway.dart';
import 'package:with_supabase/extensions/supabase/supabase_query_mapper.dart';

void main() {
  const mapper = SupabaseQueryMapper();

  PostgrestFilter mapFilter(RemoteFilter filter) {
    return mapper
        .toPostgrest(RemoteQuery(filters: <RemoteFilter>[filter]))
        .filters
        .single;
  }

  test('a null query becomes an empty PostgREST query', () {
    final query = mapper.toPostgrest(null);

    expect(query.filters, isEmpty);
    expect(query.orderBy, isEmpty);
    expect(query.limit, isNull);
    expect(query.offset, 0);
  });

  test('every operator maps to its PostgREST equivalent', () {
    final expected = <RemoteFilterOperator, PostgrestOperator>{
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

    for (final entry in expected.entries) {
      final value = switch (entry.key) {
        RemoteFilterOperator.inList ||
        RemoteFilterOperator.notInList => <Object?>['a', 'b'],
        RemoteFilterOperator.arrayContains => <Object?>['a'],
        RemoteFilterOperator.isNull || RemoteFilterOperator.isNotNull => null,
        _ => 1,
      };
      final filter = mapFilter(RemoteFilter('field', entry.key, value));
      expect(filter.operator, entry.value, reason: entry.key.name);
      expect(filter.column, 'field');
    }
  });

  test('DateTime values are normalized to ISO-8601 UTC', () {
    final filter = mapFilter(
      RemoteFilter(
        'created_at',
        RemoteFilterOperator.greaterThan,
        DateTime.utc(2030, 1, 2, 3, 4, 5),
      ),
    );

    expect(filter.value, '2030-01-02T03:04:05.000Z');
  });

  test('order, limit, and offset map as-is', () {
    final query = mapper.toPostgrest(
      const RemoteQuery(
        orderBy: <RemoteOrder>[
          RemoteOrder('title'),
          RemoteOrder('created_at', direction: RemoteSortDirection.descending),
        ],
        limit: 25,
        offset: 50,
      ),
    );

    expect(query.orderBy.first.ascending, isTrue);
    expect(query.orderBy.last.ascending, isFalse);
    expect(query.limit, 25);
    expect(query.offset, 50);
  });

  test('in and not-in operators need a non-empty list', () {
    for (final operator in <RemoteFilterOperator>[
      RemoteFilterOperator.inList,
      RemoteFilterOperator.notInList,
    ]) {
      expect(
        () => mapper.toPostgrest(
          RemoteQuery(
            filters: <RemoteFilter>[RemoteFilter('id', operator, 'x')],
          ),
        ),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.validationUnsupportedValue,
          ),
        ),
      );
      expect(
        () => mapper.toPostgrest(
          RemoteQuery(
            filters: <RemoteFilter>[RemoteFilter('id', operator, <Object?>[])],
          ),
        ),
        throwsA(isA<Failure>()),
      );
    }
  });

  test('comparison with null is rejected', () {
    expect(
      () => mapper.toPostgrest(
        const RemoteQuery(
          filters: <RemoteFilter>[
            RemoteFilter('age', RemoteFilterOperator.greaterThan),
          ],
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (value) => value.kind,
          'kind',
          FailureKind.validation,
        ),
      ),
    );
  });

  test('isNull must not carry a value', () {
    expect(
      () => mapper.toPostgrest(
        const RemoteQuery(
          filters: <RemoteFilter>[
            RemoteFilter('deleted_at', RemoteFilterOperator.isNull, 'x'),
          ],
        ),
      ),
      throwsA(isA<Failure>()),
    );
  });

  test('invalid column and table names are rejected', () {
    expect(
      () => mapper.toPostgrest(
        const RemoteQuery(
          filters: <RemoteFilter>[
            RemoteFilter('name,email', RemoteFilterOperator.equals, 'x'),
          ],
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(() => mapper.validateIdentifier('users;'), throwsA(isA<Failure>()));
  });

  test('a zero limit and negative offset are rejected', () {
    expect(
      () => mapper.toPostgrest(const RemoteQuery(limit: 0)),
      throwsA(isA<Failure>()),
    );
    expect(
      () => mapper.toPostgrest(const RemoteQuery(offset: -1)),
      throwsA(isA<Failure>()),
    );
  });
}
