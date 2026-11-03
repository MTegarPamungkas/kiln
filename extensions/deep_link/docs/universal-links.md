# Universal links

Universal link memakai `https` dan memerlukan verifikasi di sisi domain.
Extension ini hanya menerima host yang tercantum di `hosts` dan, bila diisi,
path yang cocok dengan `path_prefixes`.

## Android: assetlinks.json

Publish file berikut di `https://<host>/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.app",
      "sha256_cert_fingerprints": [
        "AA:BB:CC:..."
      ]
    }
  }
]
```

Ganti `package_name` dengan `applicationId` aplikasi dan isi fingerprint
sertifikat penandatangan. Intent filter ditambahkan otomatis oleh manifest:

```yaml
android:
  app_links:
    hosts:
      - kiln.dev
    path_prefixes: []
```

Bila `path_prefixes` di manifest diisi, Android hanya membuka aplikasi untuk
path tersebut. Kosongkan untuk semua path.

## iOS: apple-app-site-association

Publish `https://<host>/.well-known/apple-app-site-association` tanpa ekstensi:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAMID.com.example.app"],
        "components": [
          {
            "/": "/app/*",
            "comment": "Buka aplikasi untuk path /app"
          }
        ]
      }
    ]
  }
}
```

Manifest menambahkan associated domain dari `hosts`:

```yaml
ios:
  associated_domains:
    - applinks:kiln.dev
```

Enabled `Associated Domains` pada target iOS di Xcode; entitlement dibuat oleh
patch manifest.

## Checklist

1. Host memakai HTTPS dengan sertifikat valid.
2. Kedua file verifikasi dapat diakses tanpa redirect.
3. `package_name` / `appIDs` cocok dengan aplikasi yang dipasang.
4. Scheme kustom dan host di `extension.yaml` sama dengan jawaban prompt.
5. `hosts` di `DeepLinkConfig` sama dengan host yang diverifikasi.
6. Uji dengan [testing-links.md](testing-links.md) sebelum rilis.
