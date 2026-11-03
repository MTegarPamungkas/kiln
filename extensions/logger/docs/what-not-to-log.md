# Yang tidak boleh dicatat

Log sering ikut terkirim ke crash reporter, dibagikan lewat laporan bug, atau
tersimpan di perangkat. Perlakukan setiap baris log sebagai data yang bisa
dibaca orang lain.

## Jangan pernah dicatat

- Kata sandi, PIN, OTP, dan jawaban pertanyaan keamanan.
- Token akses, refresh token, API key, dan secret server.
- Header `Authorization`, cookie sesi, dan header autentikasi lain.
- Nomor kartu, CVV, rekening, dan data pembayaran.
- Isi body permintaan atau respons yang memuat data pribadi.
- Dokumen, foto, atau isi pesan pengguna.

## Hati-hati

- Email, nomor telepon, NIK, dan alamat: pakai id internal bila memungkinkan.
- URL: query sering memuat token; middleware membuang query sebelum mencatat.
- Error dari server: pesan mentah bisa memuat payload. Catat kode dan status,
  bukan isi respons.
- Stack trace: berguna untuk reproduksi, tetapi jangan menambahkan nilai input
  ke dalamnya.

## Perlindungan bawaan

- `RedactingSink` menyamarkan pesan, data, dan teks error dengan `PiiRedactor`
  sebelum record mencapai sink.
- `HttpLogMiddleware` menyamarkan header dan tidak pernah mencatat body.
- `LogExporter` menyamarkan ulang saat menggabungkan laporan.
- `BreadcrumbSink` hanya meneruskan warning dan error, dan menerima record yang
  sudah disamarkan oleh pipeline.

Redaksi adalah lapisan pertahanan terakhir, bukan izin untuk mencatat rahasia.
Bila sebuah nilai tidak diperlukan untuk mendiagnosis masalah, jangan masukkan
ke `LogRecord.data`.
