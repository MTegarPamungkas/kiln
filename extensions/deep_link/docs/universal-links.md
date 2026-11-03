# Universal links

Universal links use `https` and require verification on the domain side. This
extension only accepts hosts listed in `hosts` and, when set, paths that match
`path_prefixes`.

## Android: assetlinks.json

Publish the following file at `https://<host>/.well-known/assetlinks.json`:

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

Replace `package_name` with the application's `applicationId` and fill in the
signing certificate fingerprint. The intent filter is added automatically by the
manifest:

```yaml
android:
  app_links:
    hosts:
      - kiln.dev
    path_prefixes: []
```

If `path_prefixes` is set in the manifest, Android only opens the application for
those paths. Leave it empty for all paths.

## iOS: apple-app-site-association

Publish `https://<host>/.well-known/apple-app-site-association` without an
extension:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAMID.com.example.app"],
        "components": [
          {
            "/": "/app/*",
            "comment": "Open the app for path /app"
          }
        ]
      }
    ]
  }
}
```

The manifest adds the associated domain from `hosts`:

```yaml
ios:
  associated_domains:
    - applinks:kiln.dev
```

Enable `Associated Domains` on the iOS target in Xcode; the entitlement is
created by the manifest patch.

## Checklist

1. The host uses HTTPS with a valid certificate.
2. Both verification files are reachable without redirects.
3. `package_name` / `appIDs` match the installed application.
4. The custom scheme and host in `extension.yaml` match the prompt answers.
5. `hosts` in `DeepLinkConfig` matches the verified host.
6. Test with [testing-links.md](testing-links.md) before release.
