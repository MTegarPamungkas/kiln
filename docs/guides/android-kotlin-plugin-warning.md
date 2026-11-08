# The Kotlin Gradle Plugin warning on Android builds

A build that installs `analytics` prints:

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): posthog_flutter
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

This page explains what the warning means for a Kiln app, and why it is often a
false positive.

## Where it comes from

Flutter's Gradle plugin scans every plugin's `android/build.gradle` as **text**
and reports any file that contains `apply plugin: 'kotlin-android'`:

```kotlin
// flutter_tools/gradle/src/main/kotlin/FlutterPluginUtils.kt
val (hasKgpPlugin, hasAppPlugin, hasLibPlugin) = Triple(
    kgpRegexGroovy.containsMatchIn(scriptText),
    ...
)
```

The scan does not evaluate the branch the line lives in, so a plugin that only
applies KGP conditionally is still reported.

## Why `posthog_flutter` is reported

`posthog_flutter` 5.58.3 and newer gate the plugin application on the
`android.builtInKotlin` Gradle property:

```gradle
def builtInKotlin = providers.gradleProperty('android.builtInKotlin')
    .map { it.toBoolean() }
    .getOrElse(true)
if (!builtInKotlin) {
    apply plugin: 'kotlin-android'
}
```

The Flutter app template writes `android.builtInKotlin=false` into
`android/gradle.properties`, so the property is false in a fresh app and the
plugin does apply KGP. The warning is accurate about that, and stale about the
plugin: with built-in Kotlin enabled the plugin applies nothing.

## What to do

### Nothing, if the build works

The warning does not fail the build today. The `analytics` extension already
requires a `posthog_flutter` version that understands built-in Kotlin, so no
version bump is available or needed to silence it.

### Opt in to built-in Kotlin

`android/gradle.properties` in the app:

```properties
android.builtInKotlin=true
```

Verified on a generated app with all 26 installable extensions: the debug APK
builds and runs on an emulator, and `posthog_flutter` no longer applies KGP at
all. The warning text stays, because the scan is textual.

Only flip this once the plugins your app installs support it. A plugin that
still applies KGP imperatively while built-in Kotlin is enabled fails the build
with a conflicting-plugin error instead of a warning.

### Remove the native plugin

The analytics extension talks to PostHog through `AnalyticsGateway`, so an
HTTP-only gateway (`POST /capture`) can replace `posthog_flutter` and take the
Kotlin dependency out of the build entirely. That is the durable fix for apps
that must keep building across Flutter releases, at the cost of losing the
plugin's native session replay and automatic screen tracking.
