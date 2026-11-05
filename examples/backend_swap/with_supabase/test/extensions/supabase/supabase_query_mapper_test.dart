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

  test('query null menjadi query PostgREST kosong', () {
    final query = mapper.toPostgrest(null);

    expect(query.filters, isEmpty);
    expect(query.orderBy, isEmpty);
    expect(query.limit, isNull);
    expect(query.offset, 0);
  });

  test('setiap operator dipetakan ke operator PostgREST yang setara', () {
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

  test('nilai DateTime dinormalkan ke ISO-8601 UTC', () {
    final filter = mapFilter(
      RemoteFilter(
        'created_at',
        RemoteFilterOperator.greaterThan,
        DateTime.utc(2030, 1, 2, 3, 4, 5),
      ),
    );

    expect(filter.value, '2030-01-02T03:04:05.000Z');
  });

  test('urutan, limit, dan offset dipetakan apa adanya', () {
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

  test('operator in dan not in butuh daftar tidak kosong', () {
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

  test('perbandingan dengan null ditolak', () {
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

  test('isNull tidak boleh membawa nilai', () {
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

  test('nama kolom dan tabel tidak valid ditolak', () {
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

  test('limit nol dan offset negatif ditolak', () {
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
