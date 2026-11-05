# Native flavors not included

This extension does not create Android product flavors or iOS schemes/build
configurations. It only creates:

- `AppFlavor` values in Dart,
- an entry point per flavor,
- an env file per flavor,
- editor launch configurations.

The reason is that native product flavors touch Gradle, the Xcode project, and
signing, which differ per project. Kiln does not guess those configurations.

If the app needs a different applicationId or bundle id per flavor, add native
product flavors manually, then use `--flavor` on the Flutter command. `AppFlavor`
values can still be used for Dart behavior.
