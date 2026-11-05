import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_query_mapper.dart';

void main() {
  const mapper = AppwriteQueryMapper();

  test('filters, ordering, limit, and offset become query strings', () {
    final queries = mapper.map(
      const RemoteQuery(
        filters: <RemoteFilter>[
          RemoteFilter('done', RemoteFilterOperator.equals, true),
          RemoteFilter('title', RemoteFilterOperator.notEquals, 'draft'),
          RemoteFilter('score', RemoteFilterOperator.greaterThan, 10),
          RemoteFilter('score', RemoteFilterOperator.greaterThanOrEqual, 10),
          RemoteFilter('score', RemoteFilterOperator.lessThan, 20),
          RemoteFilter('score', RemoteFilterOperator.lessThanOrEqual, 20),
          RemoteFilter('tags', RemoteFilterOperator.inList, <String>['a', 'b']),
          RemoteFilter('tags', RemoteFilterOperator.notInList, <String>['c']),
          RemoteFilter('tags', RemoteFilterOperator.arrayContains, 'd'),
          RemoteFilter('deletedAt', RemoteFilterOperator.isNull),
          RemoteFilter('updatedAt', RemoteFilterOperator.isNotNull),
        ],
        orderBy: <RemoteOrder>[
          RemoteOrder('title'),
          RemoteOrder('score', direction: RemoteSortDirection.descending),
        ],
        limit: 25,
        offset: 50,
      ),
    );

    expect(queries, <String>[
      Query.equal('done', true),
      Query.notEqual('title', 'draft'),
      Query.greaterThan('score', 10),
      Query.greaterThanEqual('score', 10),
      Query.lessThan('score', 20),
      Query.lessThanEqual('score', 20),
      Query.equal('tags', <String>['a', 'b']),
      Query.notEqual('tags', <String>['c']),
      Query.containsAny('tags', <String>['d']),
      Query.isNull('deletedAt'),
      Query.isNotNull('updatedAt'),
      Query.orderAsc('title'),
      Query.orderDesc('score'),
      Query.limit(25),
      Query.offset(50),
    ]);
  });

  test('equals null becomes isNull and notEquals null becomes isNotNull', () {
    final queries = mapper.map(
      const RemoteQuery(
        filters: <RemoteFilter>[
          RemoteFilter('a', RemoteFilterOperator.equals),
          RemoteFilter('b', RemoteFilterOperator.notEquals),
        ],
      ),
    );

    expect(queries, <String>[Query.isNull('a'), Query.isNotNull('b')]);
  });

  test('an empty or missing query produces no Appwrite queries', () {
    expect(mapper.map(null), isEmpty);
    expect(mapper.map(const RemoteQuery()), isEmpty);
  });

  test('the encoded query carries method, attribute, and values', () {
    final decoded =
        jsonDecode(Query.equal('title', 'Kiln')) as Map<String, dynamic>;

    expect(decoded['method'], 'equal');
    expect(decoded['attribute'], 'title');
    expect(decoded['values'], <String>['Kiln']);
  });

  test('values that Appwrite cannot express are rejected', () {
    expect(
      () => mapper.map(
        const RemoteQuery(
          filters: <RemoteFilter>[
            RemoteFilter('tags', RemoteFilterOperator.inList, 'not-a-list'),
          ],
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(
      () => mapper.map(
        const RemoteQuery(
          filters: <RemoteFilter>[
            RemoteFilter('score', RemoteFilterOperator.greaterThan),
          ],
        ),
      ),
      throwsA(isA<Failure>()),
    );
    expect(
      () => mapper.map(const RemoteQuery(limit: 0)),
      throwsA(isA<Failure>()),
    );
    expect(
      () => mapper.map(const RemoteQuery(offset: -1)),
      throwsA(isA<Failure>()),
    );
  });
}
