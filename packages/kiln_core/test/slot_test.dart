import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('OrderedSlot', () {
    test('sorts by priority and keeps insertion order for ties', () {
      final slot = OrderedSlot<String>('test');

      slot.add('normal-1', priority: 10);
      slot.add('first', priority: 5);
      slot.add('normal-2', priority: 10);
      slot.add('last', priority: 20);

      expect(slot.items, ['first', 'normal-1', 'normal-2', 'last']);
      expect(slot.entries.map((entry) => entry.priority), [5, 10, 10, 20]);
    });

    test('emits the current items on every change', () async {
      final slot = OrderedSlot<String>('test');
      final emissions = <List<String>>[];
      final subscription = slot.changes.listen(emissions.add);

      slot.add('b', priority: 10);
      slot.add('a', priority: 5);
      slot.clear();

      expect(emissions, [
        ['b'],
        ['a', 'b'],
        <String>[],
      ]);
      await subscription.cancel();
    });

    test('removes every item owned by one extension', () {
      final slot = OrderedSlot<String>('test')
        ..add('one', owner: 'dio')
        ..add('two', owner: 'http_retry')
        ..add('three', owner: 'dio');

      slot.removeOwner('dio');

      expect(slot.items, ['two']);
    });

    test('remove only removes the identical item', () {
      final slot = OrderedSlot<String>('test')
        ..add('same')
        ..add('same');

      slot.remove('same');

      expect(slot.items, ['same']);
    });

    test('exposes a well-known slot name', () {
      expect(SlotNames.httpInterceptors, 'http.interceptors');
      expect(SlotNames.routerRoutes, 'router.routes');
      expect(SlotNames.appWrappers, 'app.wrappers');
    });
  });

  group('SlotRegistry', () {
    test('opens a slot once and returns the same instance', () {
      final registry = SlotRegistry();

      final first = registry.open<String>('router.routes');
      final second = registry.open<String>('router.routes');

      expect(identical(first, second), isTrue);
      expect(registry.has('router.routes'), isTrue);
      expect(registry.find<String>('router.routes'), same(first));
    });

    test('rejects opening the same name with another item type', () {
      final registry = SlotRegistry();
      registry.open<String>('mixed');

      expect(() => registry.open<int>('mixed'), throwsStateError);
      expect(registry.find<int>('mixed'), isNull);
    });

    test('dispose closes every slot', () async {
      final registry = SlotRegistry();
      registry.open<String>('one');
      registry.open<int>('two');

      await registry.dispose();

      expect(registry.has('one'), isFalse);
      expect(registry.has('two'), isFalse);
    });
  });
}
