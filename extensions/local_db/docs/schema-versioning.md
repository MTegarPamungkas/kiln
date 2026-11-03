# Schema versioning

`SchemaMigrator` menyimpan versi di koleksi `_schema` dan menjalankan langkah
migrasi yang belum diterapkan. Tambahkan langkah baru di urutan berikutnya;
jangan mengubah langkah yang sudah dirilis.

`BackupExport` mengekspor koleksi yang dipilih ke JSON dan memulihkannya lewat
`import`.
