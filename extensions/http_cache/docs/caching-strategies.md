# Strategi cache

Default:

- Hanya GET/HEAD yang di-cache.
- TTL dari `Cache-Control: max-age`, selain itu default 60 detik.
- Respons dengan `Cache-Control: no-store` tidak disimpan.
- `no-cache` menyimpan entri tetapi tidak dianggap segar.
- `stale-while-revalidate` mengembalikan entri lama lalu menyegarkan di latar
  belakang.
- Request mutasi menginvalidasi entri dengan prefix path yang sama.
- Maksimal 100 entri; entri tertua dikeluarkan lebih dulu.

Untuk data pribadi, backend sebaiknya mengirim `Cache-Control: private,
no-store` atau aplikasi menghindari cache untuk endpoint tersebut.
