# 0002 — Extension bergantung pada kapabilitas, bukan id

## Keputusan

Manifest memakai `provides` dan `requires` berisi nama capability. Extension
tidak mengimpor extension lain dan tidak menulis id extension lain.

## Alasan

Id mengikat implementasi. Capability memungkinkan backend/transport diganti
tanpa mengubah extension dependen.

## Konsekuensi

- Resolver memilih provider dan mendeteksi konflik.
- Dua provider capability yang sama ditolak.
- Slot menyediakan titik sambung untuk perilaku yang tidak bisa diekspresikan
  sebagai capability.
