import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef PaginatedRemoteDatabaseContractFactory =
    FutureOr<PaginatedRemoteDatabase> Function();

/// Behavior every [PaginatedRemoteDatabase] implementation must share.
void paginatedRemoteDatabaseContract({
  required PaginatedRemoteDatabaseContractFactory create,
  String description = 'PaginatedRemoteDatabase',
}) {
  group('$description contract', () {
    test('returns pages with a next offset until the end', () async {
      final database = await create();
      for (var index = 0; index < 5; index++) {
        await database.create('items', {'index': index});
      }

      final first = await database.queryPage(
        'items',
        query: const RemoteQuery(limit: 2),
      );
      expect(first.items, hasLength(2));
      expect(first.hasMore, isTrue);
      expect(first.nextOffset, 2);
      expect(first.totalCount, 5);

      final second = await database.queryPage(
        'items',
        query: const RemoteQuery(limit: 2, offset: 2),
      );
      expect(second.items, hasLength(2));
      expect(second.nextOffset, 4);

      final last = await database.queryPage(
        'items',
        query: const RemoteQuery(limit: 2, offset: 4),
      );
      expect(last.items, hasLength(1));
      expect(last.hasMore, isFalse);
      expect(last.nextOffset, isNull);
    });

    test('an empty collection yields an empty page', () async {
      final database = await create();

      final page = await database.queryPage('items');

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
