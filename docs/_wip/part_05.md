## Extension: state dan jaringan

Lima extension ini membentuk fondasi aplikasi: satu adapter state management
(eksklusif) dan tumpukan HTTP yang dirakit dari `dio`, `http_retry`, dan
`http_cache` lewat slot `http.interceptors`.

### bloc

```text
extensions/bloc/                            # extension state management berbasis Bloc dan Cubit
├─ extension.yaml                           # manifest: category: state · exclusive · provides: state_bloc (riverpod ditolak lewat aturan exclusive)
├─ README.md                                # panduan singkat pemasangan dan pemakaian extension bloc
├─ CHANGELOG.md                             # riwayat perubahan extension bloc per versi
├─ docs/                                    # dokumentasi pemakaian extension bloc
│  ├─ state-with-bloc.md                    # panduan mengelola state aplikasi dengan Cubit dan Bloc
│  └─ bloc-to-riverpod.md                   # panduan migrasi state dari bloc ke riverpod
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang di-render ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason dan daftar variabelnya
   └─ __brick__/                            # isi template yang disalin ke aplikasi hasil generate
      ├─ lib/                               # kode Dart yang disalin ke lib/ aplikasi
      │  ├─ bootstrap.dart                  # menyiapkan Registry dan AppBlocObserver sebelum runApp
      │  ├─ app/                            # komposisi tingkat aplikasi untuk state global
      │  │  └─ bloc_providers.dart          # MultiBlocProvider untuk bloc global
      │  ├─ core/bloc/                      # fondasi Bloc dan Cubit yang dipakai semua fitur
      │  │  ├─ app_bloc_observer.dart       # log transisi dan error ke Logger, PII disamarkan
      │  │  ├─ base_cubit.dart              # safeEmit (cek isClosed), runGuarded menjadi Failure
      │  │  ├─ async_state.dart             # sealed: initial, loading, data, failure
      │  │  ├─ async_cubit.dart             # load, refresh, retry
      │  │  ├─ bloc_transformers.dart       # debounce, throttle, droppable, restartable
      │  │  └─ session_cubit.dart           # membungkus SessionController dari kiln_core
      │  └─ features/                       # fitur contoh yang memakai state Bloc
      │     └─ counter/                     # fitur counter sebagai contoh pemakaian Cubit
      │        ├─ counter_cubit.dart        # Cubit yang menyimpan nilai counter dan mengubahnya
      │        └─ counter_page.dart         # halaman counter yang membaca CounterCubit lewat BlocBuilder
      └─ test/                              # test yang ikut ter-generate ke aplikasi user
         ├─ bootstrap_test.dart             # menguji bahwa bootstrap memasang observer Bloc dan menyiapkan Registry
         ├─ counter_cubit_test.dart         # menguji bahwa CounterCubit mengubah state sesuai aksi
         ├─ counter_page_test.dart          # menguji bahwa CounterPage menampilkan nilai counter dan bereaksi pada tombol
         └─ core/bloc/                      # test untuk fondasi Bloc di core/bloc
            ├─ app_bloc_observer_test.dart  # menguji bahwa observer mencatat transisi dan error dengan PII disamarkan
            ├─ base_cubit_test.dart         # menguji bahwa safeEmit tidak emit saat isClosed dan runGuarded menjadi Failure
            ├─ async_state_test.dart        # menguji varian sealed AsyncState: initial, loading, data, failure
            ├─ async_cubit_test.dart        # menguji bahwa load, refresh, dan retry menghasilkan urutan state yang benar
            ├─ bloc_transformers_test.dart  # menguji perilaku transformer debounce, throttle, droppable, dan restartable
            └─ session_cubit_test.dart      # menguji bahwa SessionCubit meneruskan status SessionController
```

### riverpod

```text
extensions/riverpod/                        # extension state management berbasis Riverpod
├─ extension.yaml                           # manifest: category: state · exclusive · provides: state_riverpod (bloc ditolak lewat aturan exclusive)
├─ README.md                                # panduan singkat pemasangan dan pemakaian extension riverpod
├─ CHANGELOG.md                             # riwayat perubahan extension riverpod per versi
├─ docs/                                    # dokumentasi pemakaian extension riverpod
│  ├─ state-with-riverpod.md                # panduan mengelola state aplikasi dengan provider dan Notifier
│  └─ riverpod-to-bloc.md                   # panduan migrasi state dari riverpod ke bloc
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang di-render ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason dan daftar variabelnya
   └─ __brick__/                            # isi template yang disalin ke aplikasi hasil generate
      ├─ lib/                               # kode Dart yang disalin ke lib/ aplikasi
      │  ├─ bootstrap.dart                  # menyiapkan Registry dan ProviderScope sebelum runApp
      │  ├─ app/                            # komposisi tingkat aplikasi untuk state global
      │  │  └─ provider_root.dart           # ProviderScope dengan override Registry
      │  ├─ core/riverpod/                  # fondasi Riverpod yang dipakai semua fitur
      │  │  ├─ kiln_providers.dart          # registryProvider dan kilnProvider<T>() untuk setiap kontrak
      │  │  ├─ app_provider_observer.dart   # log error provider, PII disamarkan
      │  │  ├─ async_value_x.dart           # ekstensi AsyncValue: guard menjadi Failure dan pemetaan when yang ringkas
      │  │  ├─ provider_overrides.dart      # override siap pakai untuk test
      │  │  └─ session_notifier.dart        # membungkus SessionController dari kiln_core
      │  └─ features/                       # fitur contoh yang memakai state Riverpod
      │     └─ counter/                     # fitur counter sebagai contoh pemakaian provider
      │        ├─ counter_page.dart         # halaman counter yang membaca state dari provider
      │        └─ counter_provider.dart     # provider yang menyimpan nilai counter dan mengubahnya
      └─ test/                              # test yang ikut ter-generate ke aplikasi user
         ├─ bootstrap_test.dart             # menguji bahwa bootstrap menyiapkan ProviderScope dengan Registry
         ├─ counter_page_test.dart          # menguji bahwa CounterPage menampilkan nilai counter dan bereaksi pada tombol
         ├─ counter_provider_test.dart      # menguji bahwa counter provider mengubah state sesuai aksi
         └─ core/riverpod/                  # test untuk fondasi Riverpod di core/riverpod
            ├─ kiln_providers_test.dart     # menguji bahwa registryProvider dan kilnProvider<T>() mengambil kontrak dari Registry
            ├─ app_provider_observer_test.dart  # menguji bahwa observer mencatat error provider dengan PII disamarkan
            ├─ async_value_x_test.dart      # menguji bahwa guard mengubah exception menjadi Failure dan when memetakan state
            ├─ provider_overrides_test.dart  # menguji bahwa override test mengganti kontrak dengan fake
            └─ session_notifier_test.dart   # menguji bahwa SessionNotifier meneruskan status SessionController
```

### dio

```text
extensions/dio/                             # extension HTTP client berbasis dio dan pembuka slot interceptor
├─ extension.yaml                           # manifest: provides: http_client, http_pipeline · membuka slot: http.interceptors · android: INTERNET · macos: network.client
├─ README.md                                # panduan singkat pemasangan dan pemakaian extension dio
├─ CHANGELOG.md                             # riwayat perubahan extension dio per versi
├─ docs/                                    # dokumentasi pemakaian extension dio
│  ├─ http-client.md                        # panduan membuat request dan menangani error lewat HttpClient
│  └─ interceptors.md                       # cara extension lain menempel ke slot http.interceptors
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang di-render ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason dan variabel seperti base_url dan connect_timeout
   ├─ hooks/                                # hook Mason yang jalan saat generate
   │  ├─ pubspec.yaml                       # dependensi yang dibutuhkan skrip hook
   │  └─ pre_gen.dart                       # memvalidasi base_url dan connect_timeout sebelum render
   └─ __brick__/                            # isi template yang disalin ke aplikasi hasil generate
      ├─ lib/extensions/dio/                # kode extension dio di aplikasi hasil generate
      │  ├─ http.dart                       # fasad statis Http.get, post, put, patch, delete
      │  ├─ dio_module.dart                 # mendaftarkan HttpClient dan HttpPipeline ke Registry
      │  ├─ dio_client.dart                 # implementasi kontrak HttpClient di atas Dio dengan HttpPipeline
      │  ├─ dio_config.dart                 # konfigurasi bertipe: base_url, timeout, header default
      │  ├─ dio_failure_mapper.dart         # mengubah error DioException menjadi Failure (timeout, offline, 401, 5xx)
      │  ├─ cancellation.dart               # membatalkan request saat widget dispose
      │  ├─ multipart_helper.dart           # mengunggah file multipart dengan laporan progress
      │  ├─ download_helper.dart            # mengunduh file dengan laporan progress
      │  ├─ dio_test_adapter.dart           # adapter HTTP palsu agar test tidak memakai jaringan
      │  └─ interceptors/                   # interceptor bawaan dan pintu masuk slot
      │     ├─ interceptor_slot.dart        # pintu masuk contributes dari extension lain
      │     ├─ request_id_interceptor.dart  # menambah header X-Request-Id untuk korelasi log
      │     └─ user_agent_interceptor.dart  # menambah header User-Agent berisi versi app dan platform
      └─ test/extensions/dio/               # test yang ikut ter-generate untuk extension dio
         ├─ dio_client_test.dart            # menguji bahwa DioClient mengirim request dan mengembalikan Result
         ├─ dio_module_test.dart            # menguji bahwa modul mendaftarkan HttpClient dan HttpPipeline ke Registry
         ├─ dio_failure_mapper_test.dart    # menguji bahwa DioException dipetakan ke Failure (timeout, offline, 401, 5xx)
         ├─ cancellation_test.dart          # menguji bahwa request dibatalkan saat widget dispose
         ├─ multipart_helper_test.dart      # menguji bahwa unggah multipart mengirim file dan melaporkan progress
         ├─ download_helper_test.dart       # menguji bahwa unduhan menulis file dan melaporkan progress
         ├─ interceptor_slot_test.dart      # menguji bahwa kontribusi slot dipasang sesuai urutan priority
         ├─ request_id_interceptor_test.dart  # menguji bahwa setiap request membawa header X-Request-Id
         ├─ user_agent_interceptor_test.dart  # menguji bahwa header User-Agent memuat versi app dan platform
         └─ http_client_contract_test.dart  # menjalankan suite kontrak HttpClient dari kiln_testing ke implementasi ini
```

### http_retry

```text
extensions/http_retry/                      # extension retry otomatis untuk request HTTP yang gagal sementara
├─ extension.yaml                           # manifest: requires: http_client, http_pipeline · contributes: http.interceptors, priority 20 (ditempelkan ke HttpPipeline)
├─ README.md                                # panduan singkat pemasangan dan pemakaian extension http_retry
├─ CHANGELOG.md                             # riwayat perubahan extension http_retry per versi
├─ docs/                                    # dokumentasi pemakaian extension http_retry
│  └─ retry-policy.md                       # panduan mengatur kebijakan retry, backoff, dan budget
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang di-render ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason dan daftar variabelnya
   └─ __brick__/                            # isi template yang disalin ke aplikasi hasil generate
      ├─ lib/extensions/http_retry/         # kode extension http_retry di aplikasi hasil generate
      │  ├─ http_retry_module.dart          # mendaftarkan RetryMiddleware ke Registry dan HttpPipeline
      │  ├─ retry_middleware.dart           # HttpMiddleware yang mengulang request gagal sesuai kebijakan
      │  ├─ retry_policy.dart               # menentukan kegagalan mana yang layak diulang dan berapa kali
      │  ├─ retry_settings.dart             # pengaturan bertipe: jumlah percobaan, jeda awal, dan batas backoff
      │  ├─ backoff.dart                    # menghitung jeda eksponensial dengan jitter
      │  ├─ retry_budget.dart               # membatasi total retry per jendela waktu, mencegah retry storm
      │  ├─ retry_after_parser.dart         # membaca header Retry-After (detik atau tanggal HTTP)
      │  ├─ idempotency.dart                # hanya mengulang method idempoten atau yang punya Idempotency-Key
      │  └─ retry_events.dart               # memicu callback dan log pada tiap percobaan ulang
      └─ test/extensions/http_retry/        # test yang ikut ter-generate untuk extension http_retry
         ├─ http_retry_test.dart            # menguji bahwa kegagalan sementara diulang sesuai kebijakan
         ├─ backoff_test.dart               # menguji bahwa jeda tumbuh eksponensial dan jitter tetap dalam batas
         ├─ retry_budget_test.dart          # menguji bahwa retry berhenti saat budget jendela waktu habis
         ├─ retry_after_parser_test.dart    # menguji bahwa Retry-After dalam detik maupun tanggal HTTP terbaca benar
         └─ idempotency_test.dart           # menguji bahwa hanya method idempoten atau ber-Idempotency-Key yang diulang
```

### http_cache

```text
extensions/http_cache/                      # extension cache respons HTTP dengan penyimpanan opsional
├─ extension.yaml                           # manifest: requires: http_client, http_pipeline · storage opsional (when: [storage]) · contributes: http.interceptors, priority 30
├─ README.md                                # panduan singkat pemasangan dan pemakaian extension http_cache
├─ CHANGELOG.md                             # riwayat perubahan extension http_cache per versi
├─ docs/                                    # dokumentasi pemakaian extension http_cache
│  └─ caching-strategies.md                 # panduan memilih strategi cache dan invalidasi
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang di-render ke aplikasi user
   ├─ brick.yaml                            # metadata brick Mason dan daftar variabelnya
   └─ __brick__/                            # isi template yang disalin ke aplikasi hasil generate
      ├─ lib/extensions/http_cache/         # kode extension http_cache di aplikasi hasil generate
      │  ├─ http_cache_module.dart          # mendaftarkan HttpCache ke Registry dan interceptor ke HttpPipeline
      │  ├─ cache_policy.dart               # menentukan respons mana yang boleh disimpan dan berapa lama
      │  ├─ cache_settings.dart             # pengaturan bertipe: strategi cache, TTL, dan ukuran maksimum
      │  ├─ memory_http_cache.dart          # implementasi HttpCache di memori proses
      │  ├─ cache_store.dart                # interface penyimpanan entri cache yang dipakai implementasi HttpCache
      │  ├─ storage_http_cache.dart         # HttpCache persisten lewat kontrak Storage
      │  ├─ cache_interceptor.dart          # HttpMiddleware cache yang menempel ke slot http.interceptors
      │  ├─ cache_key.dart                  # membuat kunci cache dari URL, query, dan header Vary
      │  ├─ cache_control_parser.dart       # membaca Cache-Control: max-age, no-store, no-cache, stale-while-revalidate
      │  ├─ etag_validator.dart             # memvalidasi ETag lewat If-None-Match dan respons 304
      │  ├─ stale_while_revalidate.dart     # menyajikan cache lama lalu menyegarkan di latar belakang
      │  └─ cache_invalidation.dart         # menghapus entri per prefix atau tag setelah request mutasi
      └─ test/extensions/http_cache/        # test yang ikut ter-generate untuk extension http_cache
         ├─ http_cache_test.dart            # menguji bahwa respons disajikan dari cache sesuai kebijakan
         ├─ cache_key_test.dart             # menguji bahwa kunci cache memuat URL, query, dan header Vary
         ├─ cache_control_parser_test.dart  # menguji bahwa direktif Cache-Control terbaca benar
         ├─ etag_validator_test.dart        # menguji bahwa ETag memicu If-None-Match dan respons 304 memakai cache
         ├─ stale_while_revalidate_test.dart  # menguji bahwa cache lama disajikan lalu disegarkan di latar belakang
         ├─ cache_invalidation_test.dart    # menguji bahwa request mutasi menghapus entri per prefix atau tag
         └─ storage_http_cache_test.dart    # menguji bahwa cache persisten menyimpan dan membaca entri lewat Storage
```

