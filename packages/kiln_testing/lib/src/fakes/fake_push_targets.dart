import 'package:kiln_core/kiln_core.dart';

/// [PushTargets] with in-memory storage mirroring the upsert semantics
/// backends keep: one target per provider per session.
final class FakePushTargets implements PushTargets {
  FakePushTargets({this.failure});

  Failure? failure;
  final List<String> calls = <String>[];
  final Map<String, PushTarget> _targets = <String, PushTarget>{};
  var _sequence = 0;

  PushTarget? targetFor(String id) => _targets[id];

  @override
  Future<PushTarget> register({
    required String token,
    String? providerId,
  }) async {
    calls.add('register:$token');
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    final existing = _targets.values
        .where((target) => target.providerId == providerId)
        .toList(growable: false);
    if (existing.isNotEmpty) {
      final updated = PushTarget(
        id: existing.first.id,
        identifier: token,
        providerId: existing.first.providerId,
        name: existing.first.name,
        userId: existing.first.userId,
      );
      _targets[updated.id] = updated;
      return updated;
    }
    _sequence += 1;
    final target = PushTarget(
      id: 'target-$_sequence',
      identifier: token,
      providerId: providerId,
    );
    _targets[target.id] = target;
    return target;
  }

  @override
  Future<PushTarget> update({
    required String targetId,
    required String token,
  }) async {
    calls.add('update:$targetId');
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    final existing = _targets[targetId];
    if (existing == null) {
      throw Failure(
        code: FailureCode.pushTargetsNotFound,
        message: 'Push target "$targetId" does not exist.',
        kind: FailureKind.unknown,
        details: <String, Object?>{'targetId': targetId},
      );
    }
    final updated = PushTarget(
      id: existing.id,
      identifier: token,
      providerId: existing.providerId,
      name: existing.name,
      userId: existing.userId,
    );
    _targets[targetId] = updated;
    return updated;
  }

  @override
  Future<void> unregister({required String targetId}) async {
    calls.add('unregister:$targetId');
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    if (_targets.remove(targetId) == null) {
      throw Failure(
        code: FailureCode.pushTargetsNotFound,
        message: 'Push target "$targetId" does not exist.',
        kind: FailureKind.unknown,
        details: <String, Object?>{'targetId': targetId},
      );
    }
  }
}
