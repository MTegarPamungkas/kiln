import 'package:kiln_core/kiln_core.dart';

/// Friendly failure copy supplied by the `l10n` extension.
abstract interface class FailureMessages {
  String messageFor(Failure failure);
}

/// Converts a [Failure] into a message a user can understand.
class FailurePresenter {
  const FailurePresenter({this.messages});

  final FailureMessages? messages;

  factory FailurePresenter.fromRegistry(Registry registry) {
    return FailurePresenter(
      messages: registry.readOrNull<FailureMessages>(),
    );
  }

  String present(Failure failure) {
    final localized = messages;
    if (localized != null) {
      return localized.messageFor(failure);
    }
    if (failure.code == FailureCode.networkTimeout) {
      return 'Koneksi terlalu lama. Periksa jaringan lalu coba lagi.';
    }
    if (failure.code == FailureCode.networkOffline ||
        failure.code == FailureCode.networkUnreachable) {
      return 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
    }
    if (failure.code == FailureCode.authInvalidCredentials) {
      return 'Email atau kata sandi tidak cocok.';
    }
    if (failure.code == FailureCode.permissionDenied ||
        failure.code == FailureCode.permissionPermanentlyDenied) {
      return 'Izin dibutuhkan untuk melanjutkan. Buka pengaturan aplikasi.';
    }
    if (failure.code == FailureCode.validationInvalidInput) {
      return 'Data yang dimasukkan belum valid.';
    }
    if (failure.code == FailureCode.cancelled ||
        failure.code == FailureCode.mediaCancelled) {
      return 'Tindakan dibatalkan.';
    }
    return failure.message;
  }
}
