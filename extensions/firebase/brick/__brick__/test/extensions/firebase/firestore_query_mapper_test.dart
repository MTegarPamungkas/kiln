import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_query_mapper.dart';

void main() {
  const mapper = FirestoreQueryMapper();

  test('maps every filter operator to its Firestore equivalent', () {
    const cases = <(RemoteFilter, FirestoreFilterOperator)>[
      (
        RemoteFilter('a', RemoteFilterOperator.equals, 1),
        FirestoreFilterOperator.equal,
      ),
      (
        RemoteFilter('b', RemoteFilterOperator.notEquals, 2),
        FirestoreFilterOperator.notEqual,
      ),
      (
        RemoteFilter('c', RemoteFilterOperator.greaterThan, 3),
        FirestoreFilterOperator.greaterThan,
      ),
      (
        RemoteFilter('d', RemoteFilterOperator.greaterThanOrEqual, 4),
        FirestoreFilterOperator.greaterThanOrEqual,
      ),
      (
        RemoteFilter('e', RemoteFilterOperator.lessThan, 5),
        FirestoreFilterOperator.lessThan,
      ),
      (
        RemoteFilter('f', RemoteFilterOperator.lessThanOrEqual, 6),
        FirestoreFilterOperator.lessThanOrEqual,
      ),
      (
        RemoteFilter('g', RemoteFilterOperator.inList, [7, 8]),
        FirestoreFilterOperator.inList,
      ),
      (
        RemoteFilter('h', RemoteFilterOperator.notInList, [9]),
        FirestoreFilterOperator.notInList,
      ),
      (
        RemoteFilter('i', RemoteFilterOperator.arrayContains, 'tag'),
        FirestoreFilterOperator.arrayContains,
      ),
      (
        RemoteFilter('j', RemoteFilterOperator.isNull),
        FirestoreFilterOperator.isNull,
      ),
      (
        RemoteFilter('k', RemoteFilterOperator.isNotNull),
        FirestoreFilterOperator.isNotNull,
      ),
    ];

    for (final (filter, expected) in cases) {
      final mapped = mapper.map(RemoteQuery(filters: [filter]));
      expect(mapped.filters.single.operator, expected, reason: filter.field);
    }

    final inList = mapper.map(
      const RemoteQuery(
        filters: [
          RemoteFilter('g', RemoteFilterOperator.inList, [7, 8]),
        ],
      ),
    );
    expect(inList.filters.single.value, [7, 8]);
  });

  test('null equality becomes isNull and isNotNull', () {
    final query = mapper.map(
      const RemoteQuery(
        filters: [
          RemoteFilter('deletedAt', RemoteFilterOperator.equals),
          RemoteFilter('photoUrl', RemoteFilterOperator.notEquals),
        ],
      ),
    );

    expect(query.filters[0].operator, FirestoreFilterOperator.isNull);
    expect(query.filters[1].operator, FirestoreFilterOperator.isNotNull);
  });

  test('maps ordering, limit, and offset', () {
    final query = mapper.map(
      const RemoteQuery(
        orderBy: [
          RemoteOrder('createdAt', direction: RemoteSortDirection.descending),
        ],
        limit: 20,
        offset: 40,
      ),
    );

    expect(query.orders.single.field, 'createdAt');
    expect(query.orders.single.descending, isTrue);
    expect(query.limit, 20);
    expect(query.offset, 40);
  });

  test('allows equality filters with a different orderBy field', () {
    final query = mapper.map(
      const RemoteQuery(
        filters: [RemoteFilter('done', RemoteFilterOperator.equals, true)],
        orderBy: [RemoteOrder('title')],
      ),
    );

    expect(query.filters.single.operator, FirestoreFilterOperator.equal);
    expect(query.orders.single.field, 'title');
  });

  test('allows a range filter ordered by the same field', () {
    final query = mapper.map(
      const RemoteQuery(
        filters: [RemoteFilter('score', RemoteFilterOperator.greaterThan, 10)],
        orderBy: [
          RemoteOrder('score', direction: RemoteSortDirection.descending),
        ],
      ),
    );

    expect(query.filters.single.field, 'score');
    expect(query.orders.single.field, 'score');
  });

  test('rejects a limit that is not positive', () {
    _expectFailure(
      () => mapper.map(const RemoteQuery(limit: 0)),
      FailureCode.validationInvalidInput,
    );
  });

  test('rejects a negative offset', () {
    _expectFailure(
      () => mapper.map(const RemoteQuery(offset: -1)),
      FailureCode.validationInvalidInput,
    );
  });

  test('rejects empty field names', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          filters: [RemoteFilter(' ', RemoteFilterOperator.equals, 1)],
        ),
      ),
      FailureCode.validationInvalidInput,
    );
  });

  test('rejects two range filters on different fields', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          filters: [
            RemoteFilter('score', RemoteFilterOperator.greaterThan, 10),
            RemoteFilter('rank', RemoteFilterOperator.lessThan, 3),
          ],
        ),
      ),
      FailureCode.validationUnsupportedValue,
    );
  });

  test('rejects a range filter with orderBy on another field', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          filters: [
            RemoteFilter('score', RemoteFilterOperator.greaterThan, 10),
          ],
          orderBy: [RemoteOrder('title')],
        ),
      ),
      FailureCode.validationUnsupportedValue,
    );
  });

  test('rejects more than one orderBy field', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          orderBy: [RemoteOrder('title'), RemoteOrder('createdAt')],
        ),
      ),
      FailureCode.validationUnsupportedValue,
    );
  });

  test('rejects a second disjunction filter', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          filters: [
            RemoteFilter('status', RemoteFilterOperator.inList, ['open']),
            RemoteFilter('tags', RemoteFilterOperator.arrayContains, 'urgent'),
          ],
        ),
      ),
      FailureCode.validationUnsupportedValue,
    );
  });

  test('rejects an in list that is not a list of values', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          filters: [
            RemoteFilter('status', RemoteFilterOperator.inList, 'open'),
          ],
        ),
      ),
      FailureCode.validationInvalidInput,
    );
  });

  test('rejects an empty or oversized in list', () {
    _expectFailure(
      () => mapper.map(
        const RemoteQuery(
          filters: [
            RemoteFilter('status', RemoteFilterOperator.inList, <Object>[]),
          ],
        ),
      ),
      FailureCode.validationInvalidInput,
    );
    _expectFailure(
      () => mapper.map(
        RemoteQuery(
          filters: [
            RemoteFilter(
              'status',
              RemoteFilterOperator.inList,
              List<Object>.generate(31, (index) => index),
            ),
          ],
        ),
      ),
      FailureCode.validationInvalidInput,
    );
  });
}

void _expectFailure(void Function() action, FailureCode code) {
  expect(
    action,
    throwsA(
      isA<Failure>()
          .having((value) => value.code, 'code', code)
          .having((value) => value.kind, 'kind', FailureKind.validation),
    ),
  );
}
