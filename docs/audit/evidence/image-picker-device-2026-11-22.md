# Image picker device acceptance

Date: 2026-11-22. Physical phone `c7d2692b` (Xiaomi M2007J20CG, Android 13,
API 33). Not an emulator run. No commit or deployment was made.

## Result

**K28** now has plugin-level acceptance on Android for the paths that need no
personal data. The probe used the real `image_picker` plugin and the real system
UI, not a fake gateway.

| Step | Outcome |
| --- | --- |
| Support probe | `supported`, `{camera: supported, gallery: supported}` |
| Gallery pick of a synthetic 800x600 PNG | `pick ok mime=image/jpeg bytes=14278 dims=800x600` |
| Gallery cancel (back) | `null`, not a failure — cancellation stays distinct |
| **Camera capture (owner-approved)** | `camera ok mime=image/jpeg bytes=165896 dims=1600x1200` |
| Camera cancel (back) | `null` |
| Lost-data recovery with nothing pending | `recover null` |
| Bootstrap | no errors; `image_picker` support recorded |
| Oversize pick with `max_bytes: 102400` | `gallery_failure media.invalid validation` |

The camera path is now proven end to end: the system camera activity opened, a
real shutter press produced a photo, and the plugin returned it as a 162 KB JPEG
at 1600x1200 — the config's `maxWidth`/`maxHeight` target, measured from the
encoded header, within the 5 MB byte limit. Nothing was rejected and nothing
leaked: the frame stayed within the configured bounds. The owner approved this
capture explicitly; the resulting files (picker cache copy and app cache) were
deleted afterwards and no copy was written to `DCIM/`.

The picker returned a downscaled JPEG: the config's `maxWidth`/`maxHeight` (1600)
is a target, and the system picker applied `imageQuality: 85`, so an 800x600 PNG
came back as a 14 KB JPEG. The decoded dimensions are measured from the encoded
header (`dims=800x600`), which is the same reader the byte/dimension limits use.

## Oversize rejection through the real plugin

A second run used `tool/e2e/device_probe.dart --oversize`, which renders the same
fixture with `max_bytes: 102400` (the manifest minimum). A 6 MB random-noise PNG
(1600x1200, intentionally incompressible) was pushed to the gallery, so the
system picker's downscale still produced a file above the limit:

```
KILNPROBE gallery_failure media.invalid validation
KILNPROBE gallery_cancel null
KILNPROBE camera null
KILNPROBE recover null
```

So the byte bound is enforced against a real picked file, not only against
synthetic bytes in a unit test, and the result is a typed validation failure
rather than an upload of a truncated image.

## Camera capture

The camera was opened by the plugin (system camera activity), then a shutter
press completed the capture on the owner's explicit approval:

```
KILNPROBE camera ok mime=image/jpeg bytes=165896 dims=1600x1200
KILNPROBE recover null
KILNPROBE probe_done
```

`1600x1200` is exactly the configured `maxWidth`/`maxHeight` target, read back
from the encoded header, and 162 KB is far inside the 5 MB limit — so the
downscale-and-validate path holds for a camera source too, not only for gallery
picks. Cancelling the camera instead returned `null` on an earlier run, so both
outcomes are covered.

## Deliberately not run

Camera **capture** was eventually run with the owner's explicit approval (see
above); an earlier pass opened the camera and cancelled instead. HEIC from an
iPhone, and iOS picker behaviour generally, stay open.

## Fixture

`tool/e2e/device_probe.dart --media` renders the current `image_picker` brick
into `.dart_tool/media_probe` (Android only), applies its manifest patches, and
writes `tool/e2e/media_probe_main.dart.tmpl` as `lib/main.dart`. The probe runs
three operator-driven steps in order (gallery pick, gallery cancel, camera) and
logs one `KILNPROBE` line per step, plus a lost-data recovery.

```bash
dart run tool/e2e/device_probe.dart --media
cd .dart_tool/media_probe && flutter build apk --debug
adb -s c7d2692b install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s c7d2692b shell am start -n dev.kiln.media_probe/.MainActivity
```

The test image is generated locally and pushed into `Pictures/`, then removed
after the run; no gallery photo of the owner was opened.

## Isolation and cleanup

The disposable debug app, the pushed PNG, and its MediaStore row were all
removed after the run. No owner photo, permission, or system setting was
changed. Nothing was written outside `.dart_tool/` and the temporary device file.

## What stays open

- HEIC from an iPhone, and iOS picker behaviour generally.
