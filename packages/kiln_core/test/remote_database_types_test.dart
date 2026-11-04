import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('RemotePage', () {
    test('hasMore reflects a next cursor or offset', () {
      expect(const RemotePage<Object?>(items: []).hasMore, isFalse);
      expect(
        const RemotePage<Object?>(items: [], nextOffset: 2).hasMore,
        isTrue,
      );
      expect(
        const RemotePage<Object?>(items: [], nextCursor: 'abc').hasMore,
        isTrue,
      );
    });
  });

  group('RemoteQuery', () {
    test('is const-constructible with a cursor', () {
      const query = RemoteQuery(limit: 10, cursor: 'opaque');
      expect(query.cursor, 'opaque');
      expect(query.limit, 10);
    });
  });

  group('RemoteWrite', () {
    test('insert carries data only', () {
      const write = RemoteWrite.insert({'name': 'Tegar'});
      expect(write.kind, RemoteWriteKind.insert);
      expect(write.data, {'name': 'Tegar'});
      expect(write.id, isNull);
    });

    test('update carries an id', () {
      const write = RemoteWrite.update('doc_1', {'name': 'Tegar P'});
      expect(write.kind, RemoteWriteKind.update);
      expect(write.id, 'doc_1');
    });

    test('delete carries only an id', () {
      const write = RemoteWrite.delete('doc_1');
      expect(write.kind, RemoteWriteKind.delete);
      expect(write.id, 'doc_1');
    });
  });
}
