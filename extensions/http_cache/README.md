# http_cache

Middleware cache respons HTTP untuk `HttpPipeline`.

- Cache memori secara default; memakai `Storage` bila extension storage
  terpasang.
- Menghormati `Cache-Control: max-age`, `no-store`, `no-cache`, dan
  `stale-while-revalidate`.
- Mendukung `ETag`/`If-None-Match` dan respons 304.
- Invalidasi entri setelah request mutasi.
- Kunci cache memuat method, URL, query, dan header `Vary` umum.
- Batas jumlah entri dengan eviction entri tertua.

```bash
kiln add http_cache
```
