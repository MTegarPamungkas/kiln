import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_failure_mapper.dart';

/// [PushTargets] on top of the Appwrite `Account` push target endpoints.
///
/// The capability manages the device address book only: obtaining the FCM or
/// APNs token and handling delivered messages live outside this class.
final class AppwritePushTargets implements PushTargets {
  AppwritePushTargets({required this.account})
    : _mapper = const AppwriteFailureMapper();

  final Account account;
  final AppwriteFailureMapper _mapper;

  @override
  Future<PushTarget> register({
    required String token,
    String? providerId,
  }) async {
    if (token.trim().isEmpty) {
      throw _invalidToken(token);
    }
    try {
      // The backend keeps one target per provider per session and returns the
      // updated target when one already exists — an upsert by design.
      final target = await account.createPushTarget(
        targetId: ID.unique(),
        identifier: token,
        providerId: providerId,
      );
      return _fromTarget(target);
    } on Object catch (error, stackTrace) {
      throw _mapper.map(
        error,
        scope: AppwriteFailureScope.pushTargets,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<PushTarget> update({
    required String targetId,
    required String token,
  }) async {
    if (targetId.trim().isEmpty) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message: 'A target id is required to update a push target.',
        kind: FailureKind.validation,
        details: <String, Object?>{'targetId': targetId},
      );
    }
    if (token.trim().isEmpty) {
      throw _invalidToken(token);
    }
    try {
      final target = await account.updatePushTarget(
        targetId: targetId,
        identifier: token,
      );
      return _fromTarget(target);
    } on Object catch (error, stackTrace) {
      throw _mapper.map(
        error,
        scope: AppwriteFailureScope.pushTargets,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> unregister({required String targetId}) async {
    if (targetId.trim().isEmpty) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message: 'A target id is required to unregister a push target.',
        kind: FailureKind.validation,
        details: <String, Object?>{'targetId': targetId},
      );
    }
    try {
      await account.deletePushTarget(targetId: targetId);
    } on Object catch (error, stackTrace) {
      throw _mapper.map(
        error,
        scope: AppwriteFailureScope.pushTargets,
        stackTrace: stackTrace,
      );
    }
  }

  Failure _invalidToken(String token) {
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: 'A device token is required to manage push targets.',
      kind: FailureKind.validation,
      details: <String, Object?>{'token': token},
    );
  }

  PushTarget _fromTarget(models.Target target) {
    return PushTarget(
      id: target.$id,
      identifier: target.identifier,
      providerId: target.providerId,
      name: target.name,
      userId: target.userId,
      expired: target.expired,
    );
  }
}
