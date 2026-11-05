/// What to do when a rendered file already exists in the user project.
enum CollisionPolicy { skip, overwrite, ask }

/// How one file collision should be resolved.
enum CollisionAction { create, overwrite, skip, conflict }

/// Decides whether a rendered file may replace an existing project file.
final class CollisionResolver {
  const CollisionResolver();

  CollisionAction decide({
    required bool exists,
    required String? currentHash,
    required String? ownedHash,
    required CollisionPolicy policy,
  }) {
    if (!exists) {
      return CollisionAction.create;
    }
    if (policy == CollisionPolicy.overwrite) {
      return CollisionAction.overwrite;
    }
    if (policy == CollisionPolicy.skip) {
      return CollisionAction.skip;
    }
    if (ownedHash != null && currentHash == ownedHash) {
      return CollisionAction.overwrite;
    }
    return CollisionAction.conflict;
  }
}
