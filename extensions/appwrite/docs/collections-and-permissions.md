# Koleksi, izin, dan query

Appwrite 1.8 mengganti istilah *collection* dan *document* menjadi *table* dan
*row*. Extension ini memakai API TablesDB, tetapi nama argumen kontrak tetap
`collection` agar kode aplikasi tidak bergantung pada istilah backend. Nilai
`collection` adalah id tabel Appwrite.

## Bentuk dokumen

`RemoteDatabase` mengembalikan kolom yang tersimpan ditambah `id` berisi id row
Appwrite. Kolom sistem seperti `$createdAt` tidak disalin; tambahkan kolom biasa
bila aplikasi membutuhkannya.

```dart
final created = await database.create('tasks', {
  'title': 'Kirim laporan',
  'done': false,
});
final id = created['id'];
```

## RemoteQuery yang didukung

| RemoteQuery | Query Appwrite |
| --- | --- |
| `equals` | `equal`, atau `isNull` bila nilainya null |
| `notEquals` | `notEqual`, atau `isNotNull` bila nilainya null |
| `greaterThan` | `greaterThan` |
| `greaterThanOrEqual` | `greaterThanEqual` |
| `lessThan` | `lessThan` |
| `lessThanOrEqual` | `lessThanEqual` |
| `inList` | `equal` dengan daftar nilai |
| `notInList` | `notEqual` dengan daftar nilai |
| `arrayContains` | `containsAny` dengan satu nilai |
| `isNull` | `isNull` |
| `isNotNull` | `isNotNull` |
| `RemoteOrder` naik | `orderAsc` |
| `RemoteOrder` turun | `orderDesc` |
| `limit` | `limit` |
| `offset` | `offset`, hanya bila lebih besar dari nol |

Nilai yang tidak bisa diterjemahkan, misalnya `inList` tanpa daftar, dilempar
sebagai `Failure(validation.invalid_input)` sebelum request dikirim.

## Izin

Izin di Appwrite melekat pada row dan bucket, bukan hanya pada tabel. Pola yang
umum dipakai:

- **Data milik user.** Buat row dengan izin `read("user:$userId")` dan
  `update("user:$userId")`, lalu filter dengan `RemoteFilter('userId', ...)`
  sebagai lapisan tambahan.
- **Data publik.** Berikan `read("any")` dan batasi operasi tulis ke role
  tertentu.
- **Berkas.** Bucket privat membutuhkan sesi user. `FileStorage.url` memakai
  endpoint `view` Appwrite sehingga cookie sesi ikut dikirim dari aplikasi.

`id` row selalu diisi extension; jangan memakai kolom bernama `id` untuk data
aplikasi karena nilainya akan tertimpa.
