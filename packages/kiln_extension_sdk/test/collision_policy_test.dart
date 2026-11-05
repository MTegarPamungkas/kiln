import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  const resolver = CollisionResolver();

  group('CollisionResolver', () {
    test('creates a file that does not exist under any policy', () {
      for (final policy in CollisionPolicy.values) {
        expect(
          resolver.decide(
            exists: false,
            currentHash: null,
            ownedHash: null,
            policy: policy,
          ),
          CollisionAction.create,
        );
      }
    });

    test('overwrite and skip policies are unconditional', () {
      expect(
        resolver.decide(
          exists: true,
          currentHash: 'new',
          ownedHash: 'old',
          policy: CollisionPolicy.overwrite,
        ),
        CollisionAction.overwrite,
      );
      expect(
        resolver.decide(
          exists: true,
          currentHash: 'same',
          ownedHash: 'same',
          policy: CollisionPolicy.skip,
        ),
        CollisionAction.skip,
      );
    });

    test('ask overwrites an untouched owned file', () {
      expect(
        resolver.decide(
          exists: true,
          currentHash: 'sha256:same',
          ownedHash: 'sha256:same',
          policy: CollisionPolicy.ask,
        ),
        CollisionAction.overwrite,
      );
    });

    test('ask conflicts when the user edited the file', () {
      expect(
        resolver.decide(
          exists: true,
          currentHash: 'sha256:edited',
          ownedHash: 'sha256:original',
          policy: CollisionPolicy.ask,
        ),
        CollisionAction.conflict,
      );
      expect(
        resolver.decide(
          exists: true,
          currentHash: 'sha256:edited',
          ownedHash: null,
          policy: CollisionPolicy.ask,
        ),
        CollisionAction.conflict,
      );
    });
  });
}
