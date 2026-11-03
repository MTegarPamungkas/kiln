# Alur permission

1. `PermissionKindGuard` menolak kind yang tidak diaktifkan.
2. Status diambil dari cache atau platform.
3. Bila sudah granted, selesai.
4. Bila ditolak, rationale ditampilkan (opsional).
5. Request dikirim ke platform.
6. Bila permanen, aplikasi diarahkan ke settings.
7. Cache dibersihkan saat app resume agar status dari settings terbaca ulang.
