## Extension: navigasi dan UI

Empat extension yang mengubah apa yang dilihat dan dilalui user. Semuanya
menempel ke seam di `app_basic` (`AppThemeConfig`, `AppLocalizationsConfig`,
`RouterConfig`) lewat Registry, jadi `app.dart` tidak perlu diedit.

### go_router

```text
extensions/go_router/                       # extension navigasi: router, guard, dan pemetaan tautan ke route
├─ extension.yaml                           # manifest: provides: navigation · category: navigation · exclusive · slot: router.routes
├─ README.md                                # ringkasan, cara pasang, dan contoh pemakaian extension go_router
├─ CHANGELOG.md                             # riwayat perubahan extension go_router per versi
├─ docs/                                    # dokumentasi go_router untuk developer aplikasi
│  ├─ navigation.md                         # panduan navigasi dan cara menambah route lewat slot router.routes
│  ├─ route-guards.md                       # panduan redirect berdasarkan sesi dan urutan guard
│  └─ deep-links-and-routing.md             # cara tautan dari deep_link menjadi lokasi route
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel prompt
   └─ __brick__/                            # template file yang dirender ke dalam aplikasi user
      ├─ lib/extensions/go_router/          # kode runtime extension go_router di aplikasi user
      │  ├─ go_router_module.dart            # mendaftarkan router navigasi dan slot router.routes ke Registry
      │  ├─ app_router.dart                  # membangun GoRouter dari rute, guard, dan konfigurasi router
      │  ├─ app_routes.dart                  # konstanta path dan nama route
      │  ├─ router_config.dart               # konfigurasi bertipe: initialLocation, log diagnostik, errorBuilder
      │  ├─ route_slot.dart                  # menerima AppRoute dari slot router.routes dan mengubahnya menjadi GoRoute
      │  ├─ route_guard.dart                 # interface RouteGuard, guard disusun berurutan
      │  ├─ auth_redirect.dart               # redirect sesi: belum masuk ke /sign-in, sudah masuk menjauh dari /sign-in
      │  ├─ session_refresh_listenable.dart  # mengubah SessionController.changes menjadi refreshListenable router
      │  ├─ deep_link_route_mapper.dart      # mengubah Uri dari kontrak DeepLinks menjadi lokasi route (readOrNull)
      │  ├─ notification_route_mapper.dart   # mengubah payload NotificationTap menjadi lokasi route (readOrNull)
      │  ├─ navigation_observer.dart         # mencatat ke AppLogger dan mengirim screen ke Analytics (readOrNull)
      │  ├─ not_found_page.dart              # menampilkan halaman untuk route yang tidak dikenal
      │  ├─ shell_scaffold.dart              # ShellRoute dengan navigasi bawah, berisi contoh tab
      │  └─ route_transitions.dart           # mengatur transisi halaman per platform
      └─ test/extensions/go_router/         # test extension go_router yang ikut di-generate ke aplikasi user
         ├─ app_router_test.dart              # menguji pembangunan GoRouter dari rute, guard, dan konfigurasi
         ├─ go_router_module_test.dart        # menguji bahwa modul mendaftarkan router dan slot router.routes ke Registry
         ├─ app_routes_test.dart              # menguji bahwa path dan nama route tidak ada yang duplikat
         ├─ route_slot_test.dart              # menguji bahwa AppRoute dari slot router.routes diubah menjadi GoRoute
         ├─ route_guard_test.dart             # menguji bahwa guard dijalankan sesuai urutan penyusunan
         ├─ auth_redirect_test.dart           # menguji pengalihan ke /sign-in saat belum masuk dan menjauhinya saat sudah masuk
         ├─ session_refresh_listenable_test.dart  # menguji bahwa perubahan SessionController memicu refreshListenable
         ├─ deep_link_route_mapper_test.dart  # menguji pemetaan Uri dari DeepLinks menjadi lokasi route
         ├─ notification_route_mapper_test.dart  # menguji pemetaan payload NotificationTap menjadi lokasi route
         ├─ navigation_observer_test.dart     # menguji bahwa navigasi tercatat di AppLogger dan screen terkirim ke Analytics
         ├─ not_found_page_test.dart          # menguji bahwa route tidak dikenal menampilkan halaman not found
         └─ shell_scaffold_test.dart          # menguji bahwa ShellRoute menampilkan navigasi bawah dan berpindah tab
```

### deep_link

```text
extensions/deep_link/                       # extension deep link: tautan masuk, validasi, dan pembangun tautan keluar
├─ extension.yaml                           # manifest: provides: deep_links · prompts: scheme, hosts (opsional) · android: url_schemes, app_links · ios: url_schemes, associated_domains
├─ README.md                                # ringkasan, cara pasang, dan konfigurasi extension deep_link
├─ CHANGELOG.md                             # riwayat perubahan extension deep_link per versi
├─ docs/                                    # dokumentasi deep_link untuk developer aplikasi
│  ├─ deep-links.md                         # gambaran cara kerja deep link dan konfigurasinya
│  ├─ universal-links.md                    # panduan assetlinks.json dan apple-app-site-association untuk universal link
│  └─ testing-links.md                      # cara menguji tautan dengan adb shell am start dan xcrun simctl openurl
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel prompt
   └─ __brick__/                            # template file yang dirender ke dalam aplikasi user
      ├─ lib/extensions/deep_link/          # kode runtime extension deep_link di aplikasi user
      │  ├─ deep_link_module.dart            # mendaftarkan implementasi DeepLinks ke Registry
      │  ├─ device_deep_links.dart           # implementasi DeepLinks yang membaca tautan masuk lewat gateway
      │  ├─ deep_link_gateway.dart           # membungkus plugin tautan lewat antarmuka agar bisa di-fake di test
      │  ├─ app_links_gateway.dart           # implementasi gateway yang membungkus plugin app_links agar bisa di-fake
      │  ├─ deep_link_config.dart            # konfigurasi bertipe: scheme, host yang diizinkan, daftar path yang boleh
      │  ├─ deep_link_failure_mapper.dart    # mengubah error plugin menjadi Failure(deep_link)
      │  ├─ link_allowlist.dart              # menolak scheme dan host tidak dikenal sebelum sampai ke router
      │  ├─ link_normalizer.dart             # menormalkan tautan: huruf kecil, buang parameter pelacak, rapikan path
      │  ├─ link_deduplicator.dart           # mengabaikan tautan sama dalam jendela singkat, waktunya dari Clock
      │  ├─ pending_link_buffer.dart         # menyimpan tautan yang tiba sebelum listener siap, diputar ulang sekali
      │  └─ app_link_builder.dart            # membangun tautan keluar (share, email) dengan scheme proyek
      └─ test/extensions/deep_link/         # test extension deep_link yang ikut di-generate ke aplikasi user
         ├─ device_deep_links_test.dart         # menguji bahwa tautan masuk dari gateway diteruskan lewat DeepLinks
         ├─ deep_link_module_test.dart          # menguji bahwa modul mendaftarkan DeepLinks ke Registry
         ├─ deep_link_config_test.dart          # menguji pembentukan konfigurasi dari scheme, host, dan daftar path
         ├─ deep_link_failure_mapper_test.dart  # menguji bahwa error plugin diubah menjadi Failure(deep_link)
         ├─ link_allowlist_test.dart            # menguji bahwa scheme dan host tidak dikenal ditolak
         ├─ link_normalizer_test.dart           # menguji huruf kecil, pembuangan parameter pelacak, dan perapian path
         ├─ link_deduplicator_test.dart         # menguji bahwa tautan sama diabaikan dalam jendela waktu Clock
         ├─ pending_link_buffer_test.dart       # menguji bahwa tautan sebelum listener siap diputar ulang sekali
         ├─ app_link_builder_test.dart          # menguji pembangunan tautan keluar dengan scheme proyek
         └─ deep_links_contract_test.dart       # menjalankan suite kontrak DeepLinks dari kiln_testing ke implementasi ini
```

### theme

```text
extensions/theme/                           # extension tema aplikasi: warna, tipografi, token desain, dan mode terang atau gelap
├─ extension.yaml                           # manifest: provides: theme · category: theme · exclusive · prompts: seed_color, font_family, corner_radius
├─ README.md                                # ringkasan, cara pasang, dan contoh pemakaian extension theme
├─ CHANGELOG.md                             # riwayat perubahan extension theme per versi
├─ docs/                                    # dokumentasi theme untuk developer aplikasi
│  ├─ theme.md                              # gambaran theme, konfigurasi, dan mode terang atau gelap
│  ├─ design-tokens.md                      # panduan token desain: warna, spasi, radius, dan tipografi
│  └─ rebranding.md                         # cara mengganti seed color tanpa menyentuh fitur
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel prompt
   └─ __brick__/                            # template file yang dirender ke dalam aplikasi user
      ├─ lib/extensions/theme/              # kode runtime extension theme di aplikasi user
      │  ├─ theme_module.dart                # mendaftarkan AppThemeConfig dan ThemeModeController ke Registry
      │  ├─ brand_theme.dart                 # merakit ThemeData terang dan gelap dari skema warna, teks, dan komponen
      │  ├─ theme_config.dart                # konfigurasi bertipe: seed color, font, radius, kepadatan
      │  ├─ color_schemes.dart               # membuat ColorScheme light dan dark dari seed, termasuk kontras tinggi
      │  ├─ text_styles.dart                 # menyusun skala tipografi aplikasi
      │  ├─ component_themes.dart            # menata tema komponen: AppBar, tombol, input, kartu, dialog, SnackBar, NavigationBar
      │  ├─ design_tokens.dart               # mendefinisikan AppSpacing dan AppRadius sebagai ThemeExtension
      │  ├─ semantic_colors.dart             # mendefinisikan warna success, warning, dan info sebagai ThemeExtension
      │  ├─ system_ui_style.dart             # mengatur gaya status bar dan navigation bar sesuai brightness
      │  ├─ theme_mode_controller.dart       # menyimpan ThemeMode yang dapat diubah dan memberi tahu AppShell
      │  ├─ theme_mode_store.dart            # menyimpan pilihan mode lewat Storage bila terpasang (readOrNull)
      │  ├─ theme_context_x.dart             # akses pintas lewat context.colors, context.spacing, dan context.semantic
      │  └─ widgets/                         # widget siap pakai untuk mengubah tema
      │     └─ theme_mode_switcher.dart      # menampilkan pilihan Sistem, Terang, dan Gelap
      └─ test/extensions/theme/             # test extension theme yang ikut di-generate ke aplikasi user
         ├─ brand_theme_test.dart             # menguji bahwa ThemeData terang dan gelap terbentuk dari konfigurasi
         ├─ theme_module_test.dart            # menguji bahwa modul mendaftarkan konfigurasi tema ke Registry
         ├─ theme_config_test.dart            # menguji nilai seed color, font, radius, dan kepadatan di konfigurasi
         ├─ color_schemes_test.dart           # menguji ColorScheme light, dark, dan kontras tinggi dari seed
         ├─ component_themes_test.dart        # menguji tema AppBar, tombol, input, kartu, dialog, SnackBar, NavigationBar
         ├─ design_tokens_test.dart           # menguji nilai AppSpacing dan AppRadius sebagai ThemeExtension
         ├─ semantic_colors_test.dart         # menguji warna success, warning, dan info sebagai ThemeExtension
         ├─ theme_mode_controller_test.dart   # menguji bahwa mengubah ThemeMode memberi tahu pendengar
         ├─ theme_mode_store_test.dart        # menguji penyimpanan pilihan mode lewat Storage dan perilaku tanpa Storage
         ├─ theme_mode_switcher_test.dart     # menguji bahwa memilih Sistem, Terang, atau Gelap mengubah ThemeMode
         ├─ contrast_test.dart                # menguji rasio kontras teks terhadap latar
         └─ theme_golden_test.dart            # menguji swatch warna light dan dark terhadap golden
```

### l10n

```text
extensions/l10n/                            # extension lokalisasi: locale, pesan, plural, dan format menurut locale
├─ extension.yaml                           # manifest: provides: l10n · category: l10n · exclusive · prompts: locales, fallback_locale · dependency: flutter_localizations (sdk), intl
├─ README.md                                # ringkasan, cara pasang, dan contoh pemakaian extension l10n
├─ CHANGELOG.md                             # riwayat perubahan extension l10n per versi
├─ docs/                                    # dokumentasi l10n untuk developer aplikasi
│  ├─ l10n.md                               # gambaran l10n, pilihan locale, dan cara memakai string
│  ├─ adding-a-language.md                  # langkah menambahkan sebuah bahasa beserta terjemahannya
│  └─ formatting.md                         # panduan format tanggal, angka, mata uang, dan plural
├─ test/                                    # test tingkat extension, jalan di repo kiln dan bukan di aplikasi user
│  ├─ manifest_test.dart                    # memastikan extension.yaml valid terhadap extension.schema.json
│  ├─ render_test.dart                      # merender brick ke folder temp, hasilnya harus sama dengan golden
│  ├─ analyze_test.dart                     # hasil render harus lolos dart analyze tanpa peringatan
│  └─ goldens/rendered/                     # hasil render acuan untuk render_test, generate lewat kiln ext test --update-goldens
└─ brick/                                   # brick Mason yang dirender menjadi kode extension di aplikasi user
   ├─ brick.yaml                            # metadata brick Mason: nama, versi, dan variabel prompt
   └─ __brick__/                            # template file yang dirender ke dalam aplikasi user
      ├─ lib/extensions/l10n/               # kode runtime extension l10n di aplikasi user
      │  ├─ l10n_module.dart                 # mendaftarkan AppLocalizationsConfig dan LocaleController ke Registry
      │  ├─ l10n_delegate.dart               # membuat LocalizationsDelegate yang memuat string untuk locale aktif
      │  ├─ l10n_strings.dart                # menyimpan teks antarmuka untuk tiap bahasa yang didukung
      │  ├─ l10n_config.dart                 # konfigurasi bertipe: locale yang didukung, locale cadangan
      │  ├─ locale_resolution.dart           # mengubah locale perangkat menjadi locale yang didukung (id_ID menjadi id)
      │  ├─ locale_controller.dart           # menyimpan locale yang dapat diubah, null berarti ikut sistem
      │  ├─ locale_store.dart                # menyimpan pilihan locale lewat Storage bila terpasang (readOrNull)
      │  ├─ message_formatter.dart           # memformat pesan: placeholder bernama, escape kurung kurawal
      │  ├─ plural_rules.dart                # memilih bentuk plural: one dan other untuk Inggris, satu bentuk untuk Indonesia
      │  ├─ locale_formatters.dart           # memformat tanggal, angka, dan mata uang menurut locale
      │  ├─ failure_messages.dart            # menyediakan pesan ramah per FailureCode, dipakai failure_presenter di app_basic
      │  └─ widgets/                         # widget siap pakai untuk memilih bahasa
      │     └─ language_switcher.dart        # menampilkan pilihan bahasa untuk mengubah locale aplikasi
      └─ test/extensions/l10n/              # test extension l10n yang ikut di-generate ke aplikasi user
         ├─ l10n_test.dart                    # menguji bahwa LocalizationsDelegate memuat string sesuai locale
         ├─ l10n_module_test.dart             # menguji bahwa modul mendaftarkan konfigurasi lokalisasi ke Registry
         ├─ l10n_config_test.dart             # menguji locale yang didukung dan locale cadangan di konfigurasi
         ├─ locale_resolution_test.dart       # menguji locale perangkat menjadi locale yang didukung (id_ID menjadi id)
         ├─ locale_controller_test.dart       # menguji bahwa locale dapat diubah dan null berarti ikut sistem
         ├─ locale_store_test.dart            # menguji penyimpanan pilihan locale lewat Storage dan perilaku tanpa Storage
         ├─ message_formatter_test.dart       # menguji placeholder bernama dan escape kurung kurawal
         ├─ plural_rules_test.dart            # menguji bentuk plural one dan other (Inggris) serta satu bentuk (Indonesia)
         ├─ locale_formatters_test.dart       # menguji format tanggal, angka, dan mata uang menurut locale
         ├─ failure_messages_test.dart        # menguji bahwa tiap FailureCode punya pesan ramah
         ├─ language_switcher_test.dart       # menguji bahwa memilih bahasa mengubah locale aplikasi
         └─ l10n_coverage_test.dart           # menguji bahwa setiap key bahasa utama ada di semua bahasa lain
```

