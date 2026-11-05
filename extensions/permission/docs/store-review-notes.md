# Store review notes

Both the App Store and Google Play can reject an app that requests a permission
without an obvious, in-context reason. Treat every permission as a review risk.

- **Request only what you use.** The `kinds` prompt limits the active
  `PermissionKind`s at install time, so the manifest never asks for more than the
  app actually triggers.
- **Explain before the dialog.** Show an app-owned rationale that names the benefit
  before the system prompt; the copy lives in the app, not the SDK.
- **Match the platform strings.** Android `AndroidManifest` permissions and iOS
  `NS*UsageDescription` keys must describe the same reason the app shows in the UI.

If a feature is optional, gate the permission request behind that feature rather
than asking at first launch — fewer prompts, fewer rejections.
