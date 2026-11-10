// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Aplikasi Kiln';

  @override
  String get readyTitle => 'Aplikasi siap';

  @override
  String get readyBody =>
      'Kerangka Kiln berjalan. Mulai bangun fitur di folder lib/features.';

  @override
  String get starterHint =>
      'Tambahkan extension lewat kiln add, lalu jalankan kiln doctor.';

  @override
  String get errorTitle => 'Aplikasi gagal dimulai';

  @override
  String get errorBody =>
      'Periksa konfigurasi proyek, lalu jalankan ulang aplikasi.';

  @override
  String get failureTitle => 'Terjadi kesalahan';

  @override
  String get failureBody =>
      'Silakan coba lagi. Bila masalah berlanjut, hubungi dukungan.';

  @override
  String get actionRetry => 'Coba lagi';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionClose => 'Tutup';

  @override
  String get languageLabel => 'Bahasa';

  @override
  String get languageFollowSystem => 'Ikuti sistem';

  @override
  String get languageName => 'Bahasa Indonesia';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      zero: 'Tidak ada item',
    );
    return '$_temp0';
  }

  @override
  String helloName(String name) {
    return 'Halo, $name!';
  }

  @override
  String get failureNetwork =>
      'Terjadi masalah jaringan. Periksa koneksi lalu coba lagi.';

  @override
  String get failureNetworkOffline =>
      'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';

  @override
  String get failureAuth =>
      'Sesi atau kredensial tidak valid. Masuk kembali untuk melanjutkan.';

  @override
  String get failureAuthExpired => 'Sesi berakhir. Silakan masuk kembali.';

  @override
  String get failureAuthEmail => 'Verifikasi email Anda terlebih dahulu.';

  @override
  String get failurePermission =>
      'Izin dibutuhkan untuk melanjutkan. Buka pengaturan aplikasi.';

  @override
  String get failurePermissionPermanently =>
      'Izin diblokir. Aktifkan lewat pengaturan aplikasi.';

  @override
  String get failureValidation => 'Data yang dimasukkan belum valid.';

  @override
  String get failureConfiguration => 'Konfigurasi aplikasi belum lengkap.';

  @override
  String get failureStorage => 'Data gagal disimpan atau dibaca. Coba lagi.';

  @override
  String get failureSecureStorage =>
      'Penyimpanan aman tidak tersedia di perangkat ini.';

  @override
  String get failureDatabase =>
      'Basis data lokal sedang bermasalah. Coba lagi.';

  @override
  String get failureRemoteDatabase =>
      'Server data tidak dapat dihubungi. Coba lagi.';

  @override
  String get failureFile => 'Berkas tidak dapat diproses. Coba lagi.';

  @override
  String get failureNotifications =>
      'Notifikasi tidak tersedia. Periksa izin notifikasi.';

  @override
  String get failureDeepLink => 'Tautan tidak valid atau tidak dapat dibuka.';

  @override
  String get failureMedia => 'Media tidak dapat dibuka atau diambil.';

  @override
  String get failureCache => 'Cache tidak tersedia. Data akan dimuat ulang.';

  @override
  String get failureSession => 'Sesi berakhir. Silakan masuk kembali.';

  @override
  String get failureCancelled => 'Tindakan dibatalkan.';

  @override
  String get failureUnavailable => 'Fitur ini belum tersedia.';

  @override
  String get failureUnsupported => 'Fitur ini tidak didukung di perangkat ini.';

  @override
  String get failureUnexpected => 'Terjadi kesalahan tak terduga. Coba lagi.';
}
