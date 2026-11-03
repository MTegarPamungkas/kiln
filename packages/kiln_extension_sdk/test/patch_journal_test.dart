import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('PatchJournal', () {
    test('reference-counts owners and reports the last removal', () {
      final journal = PatchJournal()
        ..register('android.permission.INTERNET', 'dio')
        ..register('android.permission.INTERNET', 'rest_auth');

      expect(journal.referenceCount('android.permission.INTERNET'), 2);
      expect(journal.ownersOf('android.permission.INTERNET'), {
        'dio',
        'rest_auth',
      });
      expect(journal.unregister('android.permission.INTERNET', 'dio'), isFalse);
      expect(
        journal.unregister('android.permission.INTERNET', 'rest_auth'),
        isTrue,
      );
      expect(journal.referenceCount('android.permission.INTERNET'), 0);
    });

    test('unregistering an unknown patch reports no remaining owners', () {
      expect(PatchJournal().unregister('missing', 'dio'), isTrue);
    });

    test('round-trips through JSON', () {
      final journal = PatchJournal()
        ..register('patch.one', 'a')
        ..register('patch.one', 'b');

      final restored = PatchJournal.fromJson(journal.toJson());

      expect(restored.ownersOf('patch.one'), {'a', 'b'});
    });
  });
}
