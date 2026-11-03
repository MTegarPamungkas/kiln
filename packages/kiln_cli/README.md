# kiln_cli

Command line interface Kiln.

```bash
kiln create my_app --with dio --answer base_url=https://api.example.com
kiln add dio
kiln doctor
kiln remove dio --yes
```

Perintah dan exit code dijelaskan di
[docs/cli/reference.md](../../docs/cli/reference.md).

Bundle brick dan manifest extension di `lib/src/bundles/` dihasilkan oleh
`tool/bundle.dart`; jangan diedit manual.
