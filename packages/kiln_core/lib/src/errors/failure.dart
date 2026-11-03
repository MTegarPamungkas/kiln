import 'failure_codes.dart';

/// Broad category of a [Failure], used for routing, presentation, and retry.
enum FailureKind {
  network,
  authentication,
  authorization,
  permission,
  validation,
  configuration,
  storage,
  database,
  file,
  notification,
  deepLink,
  media,
  cache,
  session,
  cancelled,
  unavailable,
  unsupported,
  unknown,
}

/// The single error type that crosses a Kiln contract boundary.
///
/// Contracts throw a [Failure]; feature code may convert it into a
/// `Result` with `Result.guard`. A [Failure] is a value: two failures with the
/// same code, message, kind, and details are equal.
final class Failure implements Exception {
  const Failure({
    required this.code,
    required this.message,
    this.kind = FailureKind.unknown,
    this.cause,
    this.stackTrace,
    this.details = const <String, Object?>{},
    this.isRetryable = false,
  });

  /// Wraps an arbitrary error while keeping the original cause and stack.
  factory Failure.from(
    Object error, {
    FailureCode? code,
    String? message,
    FailureKind? kind,
    StackTrace? stackTrace,
  }) {
    if (error is Failure) {
      return error;
    }
    return Failure(
      code: code ?? FailureCode.unexpected,
      message: message ?? error.toString(),
      kind: kind ?? FailureKind.unknown,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  final FailureCode code;
  final String message;
  final FailureKind kind;
  final Object? cause;
  final StackTrace? stackTrace;
  final Map<String, Object?> details;
  final bool isRetryable;

  bool get isCancelled =>
      code == FailureCode.cancelled ||
      code == FailureCode.mediaCancelled ||
      code == FailureCode.authCancelled;

  bool get isAuthFailure =>
      kind == FailureKind.authentication || kind == FailureKind.authorization;

  bool get isPermissionFailure =>
      kind == FailureKind.permission ||
      code == FailureCode.permissionDenied ||
      code == FailureCode.permissionPermanentlyDenied ||
      code == FailureCode.permissionRestricted;

  Failure copyWith({
    FailureCode? code,
    String? message,
    FailureKind? kind,
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
    bool? isRetryable,
  }) {
    return Failure(
      code: code ?? this.code,
      message: message ?? this.message,
      kind: kind ?? this.kind,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      details: details ?? this.details,
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.code == code &&
      other.message == message &&
      other.kind == kind &&
      other.isRetryable == isRetryable;

  @override
  int get hashCode => Object.hash(code, message, kind, isRetryable);

  @override
  String toString() => 'Failure(${code.value}, ${kind.name}): $message';
}
