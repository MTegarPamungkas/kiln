import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef DeepLinksContractFactory =
    ({DeepLinks deepLinks, void Function(Uri link) emit}) Function();

/// Behavior every [DeepLinks] implementation must share.
void deepLinksContract({
  required DeepLinksContractFactory create,
  String description = 'DeepLinks',
}) {
  group('$description contract', () {
    test('exposes an initial link or null', () {
      final harness = create();

      expect(harness.deepLinks.initialLink, anyOf(isNull, isA<Uri>()));
    });

    test('emits incoming links', () async {
      final harness = create();
      final links = <Uri>[];
      final subscription = harness.deepLinks.links.listen(links.add);
      final link = Uri.parse('https://kiln.dev/profile/42');

      harness.emit(link);

      expect(links, [link]);

      await subscription.cancel();
      await harness.deepLinks.dispose();
    });
  });
}
