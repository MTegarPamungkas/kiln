# Menulis extension

## 1. Scaffold

```bash
kiln ext new hello --name "Hello extension" --provides hello
```

Perintah ini membuat:

```text
extensions/hello/
├─ extension.yaml
├─ pubspec.yaml          # dependency dev untuk menjalankan test extension
├─ README.md
├─ CHANGELOG.md
├─ docs/
├─ test/                 # manifest, render, analyze
└─ brick/
   ├─ brick.yaml
   └─ __brick__/
      ├─ lib/extensions/hello/
      └─ test/extensions/hello/
```

## 2. Manifest

Isi `id`, `name`, `category`, `tier`, `provides`, `requires`, prompt, slot,
dependency, patch native, dan compatibility. Lihat
[extension-manifest.md](../extension-manifest.md).

## 3. Module

Module mendaftarkan kontrak, bukan implementasi ke kode aplikasi:

```dart
final class HelloModule extends KilnModule {
  const HelloModule();

  @override
  String get id => 'hello';

  @override
  Set<String> get provides => const {'hello'};

  @override
  void register(Registry registry) {
    registry.registerSingleton<HelloService>(HelloService());
  }
}
```

Kontrak yang dipakai aplikasi didefinisikan di `kiln_core`. Jangan membuat
fasad statis atau global registry. Kode aplikasi membaca layanan lewat
`RegistryScope`/`Registry`.

## 4. Aturan

- Extension tidak mengimpor extension lain.
- Bergantung pada capability, bukan id.
- Sediakan gateway untuk plugin yang sulit dites.
- Petakan error package menjadi `Failure` dengan `FailureCode` stabil.
- Patch native harus idempoten dan punya id stabil.
- Jangan mengedit file milik extension lain atau `extensions.g.dart`.
- Prompt rahasia tidak ditulis ke `kiln.yaml`.

## 5. Uji dan kemas

```bash
kiln ext validate extensions/hello
kiln ext test extensions/hello
kiln ext pack extensions/hello
```

`pack` menghasilkan `hello-0.1.0.tgz`. `publish` menunggu fase registry.
