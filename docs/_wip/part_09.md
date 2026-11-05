## Extensions: platform

Four extensions that wrap device capabilities. Nearly all of them have a
`*_gateway.dart`: platform plugins are hard to test, so the logic (status mapping,
streams, scheduling) is separated from the plugin calls and tested with fakes.

`permission` touches the most native files (Android manifest, iOS plist, Podfile
flags), so it gets a `kinds` prompt so that only the selected permissions are
added to the project.

### permission

```text
extensions/permission/
├─ extension.yaml                           # manifest: provides: permission · category: platform · exclusive · prompts: kinds (multi-select) · patch per kind: android, plist, podfile PERMISSION_*
├─ README.md                                # introduction to the permission extension: what it does, how to install it, and usage examples
├─ CHANGELOG.md                             # changelog of the permission extension per version
├─ docs/                                    # permission extension documentation for users and contributors
│  ├─ permissions.md                        # list of supported permission kinds with their native patches
│  ├─ permission-flow.md                    # explains the permission flow: status, rationale, request, open settings
│  └─ store-review-notes.md                 # explains why only the selected permissions are added (App Store and Play)
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick: templates rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and template variables
   └─ __brick__/                            # template contents rendered into the application project
      ├─ lib/extensions/permission/                 # permission extension code rendered into the application lib
      │  ├─ permission_module.dart                  # registers the Permissions implementation with the Registry
      │  ├─ device_permissions.dart                 # Permissions contract implementation on top of PermissionGateway
      │  ├─ permission_config.dart                  # typed configuration: active kinds, default rationale text
      │  ├─ permission_gateway.dart                 # wraps permission_handler (SdkPermissionGateway) so it can be faked in tests
      │  ├─ permission_failure_mapper.dart          # maps plugin errors to Failure(permission or unavailable)
      │  ├─ permission_kind_guard.dart              # rejects kinds that are not enabled with Failure(configuration), not a native crash
      │  ├─ permission_flow.dart                    # runs ensure(kind): status, rationale, request, to settings when permanently denied
      │  ├─ permission_group.dart                   # requests several kinds at once, e.g. camera and microphone for video
      │  ├─ permission_status_cache.dart            # reduces repeated platform calls, the cache is invalidated on onResume
      │  ├─ permission_resume_observer.dart         # re-checks the status after the user returns from settings (Lifecycle)
      │  └─ widgets/                                # ready-made permission widgets: gate and dialogs
      │     ├─ permission_gate.dart                 # shows the child only when granted, otherwise the fallback
      │     ├─ permission_rationale_dialog.dart     # dialog that explains the reason for the permission before the system prompt appears
      │     └─ open_settings_dialog.dart            # dialog that sends the user to settings when the permission is permanently denied
      └─ test/extensions/permission/                # tests that are also rendered into the app and run there
         ├─ device_permissions_test.dart            # tests that DevicePermissions forwards status and requests to the fake gateway
         ├─ permission_module_test.dart             # tests that the module registers Permissions with the Registry
         ├─ permission_config_test.dart             # tests the default active kinds and rationale text
         ├─ permission_failure_mapper_test.dart     # tests mapping plugin errors to Failure permission or unavailable
         ├─ permission_kind_guard_test.dart         # tests that a disabled kind yields Failure(configuration)
         ├─ permission_flow_test.dart               # tests the ensure flow: status, rationale, request, and the route to settings
         ├─ permission_group_test.dart              # tests requesting several kinds at once and merging their results
         ├─ permission_status_cache_test.dart       # tests that status is cached and invalidated on onResume
         ├─ permission_resume_observer_test.dart    # tests re-checking the status after the user returns from settings
         ├─ permission_gate_test.dart               # tests that PermissionGate shows the child only when granted
         ├─ permission_dialogs_test.dart            # tests the text and actions of the rationale and open settings dialogs
         └─ permissions_contract_test.dart          # runs the Permissions contract suite from kiln_testing against this implementation
```

### connectivity

```text
extensions/connectivity/
├─ extension.yaml                           # manifest: provides: connectivity · category: connectivity · exclusive · prompts: probe_url (optional), probe_interval
├─ README.md                                # introduction to the connectivity extension: what it does, how to install it, and usage examples
├─ CHANGELOG.md                             # changelog of the connectivity extension per version
├─ docs/                                    # connectivity extension documentation for users and contributors
│  ├─ connectivity.md                       # guide to using NetworkMonitor, its configuration, and the network status widgets
│  └─ offline-handling.md                   # explains the difference between being online on the network and the server being reachable; when to use the probe
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick: templates rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and template variables
   └─ __brick__/                            # template contents rendered into the application project
      ├─ lib/extensions/connectivity/               # connectivity extension code rendered into the application lib
      │  ├─ connectivity_module.dart                # registers NetworkMonitor with the Registry
      │  ├─ device_network_monitor.dart             # NetworkMonitor contract implementation on top of ConnectivityGateway
      │  ├─ connectivity_config.dart                # typed configuration: probe URL, interval, timeout, debounce window
      │  ├─ connectivity_gateway.dart               # wraps connectivity_plus (SdkConnectivityGateway) so it can be faked in tests
      │  ├─ connectivity_failure_mapper.dart        # maps plugin errors to Failure(unavailable)
      │  ├─ reachability_probe.dart                 # sends a HEAD to the probe URL through the HttpClient contract (readOrNull), optional
      │  ├─ status_stabilizer.dart                  # dampens flapping Wi-Fi using the Debouncer from kiln_core
      │  ├─ reconnect_trigger.dart                  # runs pending actions when the status changes to online
      │  ├─ offline_guard_middleware.dart           # http.interceptors middleware (when: http_pipeline), fails fast with Failure(network) when offline
      │  └─ widgets/                                # ready-made widgets for showing network status
      │     ├─ offline_banner.dart                  # shows a banner when offline, does not appear while the status is still unknown
      │     └─ network_status_builder.dart          # builds a widget according to the current NetworkStatus
      └─ test/extensions/connectivity/              # tests that are also rendered into the app and run there
         ├─ device_network_monitor_test.dart        # tests that NetworkMonitor status and stream follow the fake gateway
         ├─ connectivity_module_test.dart           # tests that the module registers NetworkMonitor with the Registry
         ├─ connectivity_config_test.dart           # tests the default probe URL, interval, timeout, and debounce window
         ├─ connectivity_failure_mapper_test.dart   # tests mapping plugin errors to Failure(unavailable)
         ├─ reachability_probe_test.dart            # tests the HEAD probe: success, failure, and skipped when HttpClient is absent
         ├─ status_stabilizer_test.dart             # tests that flapping Wi-Fi is dampened according to the debounce window
         ├─ reconnect_trigger_test.dart             # tests that pending actions run when the status changes to online
         ├─ offline_guard_middleware_test.dart      # tests that requests fail fast with Failure(network) when offline
         ├─ offline_banner_test.dart                # tests that the banner appears when offline and is hidden while the status is unknown
         ├─ network_status_builder_test.dart        # tests that the builder is called according to the NetworkStatus
         └─ connectivity_contract_test.dart         # runs the NetworkMonitor contract suite from kiln_testing against this implementation
```

### notifications

```text
extensions/notifications/
├─ extension.yaml                           # manifest: provides: notifications · category: notifications · exclusive · prompts: default_channel, small_icon, exact_alarms · platform: android, ios
├─ README.md                                # introduction to the notifications extension: what it does, how to install it, and usage examples
├─ CHANGELOG.md                             # changelog of the notifications extension per version
├─ docs/                                    # notifications extension documentation for users and contributors
│  ├─ notifications.md                      # guide to using Notifications: permissions, channels, scheduling, and taps
│  ├─ android-channels.md                   # how to define and use Android notification channels
│  ├─ scheduling-and-timezones.md           # explains the device time zone, DST, and scheduling limits
│  └─ troubleshooting-delivery.md           # delivery troubleshooting guide: Android battery optimization, iOS delegate, web limits
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick: templates rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and template variables
   └─ __brick__/                            # template contents rendered into the application project
      ├─ lib/extensions/notifications/              # notifications extension code rendered into the application lib
      │  ├─ notifications_module.dart               # registers the Notifications implementation with the Registry
      │  ├─ device_notifications.dart               # Notifications contract implementation on top of NotificationGateway
      │  ├─ notification_gateway.dart               # interface that wraps the notification plugin so it can be faked in tests
      │  ├─ plugin_notification_gateway.dart        # gateway implementation that calls the notification plugin on the device
      │  ├─ notifications_config.dart               # typed configuration: default channel, small icon, sound, exact alarm policy
      │  ├─ notification_failure_mapper.dart        # maps plugin errors to Failure(notifications, permission, or unavailable)
      │  ├─ notification_channels.dart              # defines the Android channels created at startup
      │  ├─ timezone_resolver.dart                  # determines tz.local from the device time zone, not UTC
      │  ├─ notification_payload.dart               # encodes a typed JSON payload (route, arguments) with a size limit
      │  ├─ notification_id_allocator.dart          # builds stable ids from a string key, preventing id collisions
      │  ├─ notification_tap_hub.dart               # merges foreground taps, background taps, and launchTap
      │  ├─ background_tap_handler.dart             # receives taps in the background via a top-level @pragma('vm:entry-point') function
      │  ├─ notification_permission_flow.dart       # requests permission at the right moment through the Permissions contract (readOrNull)
      │  └─ reminder_scheduler.dart                 # reschedules reminders idempotently per key, safe to call on every start
      └─ test/extensions/notifications/             # tests that are also rendered into the app and run there
         ├─ device_notifications_test.dart          # tests that DeviceNotifications forwards commands to the fake gateway
         ├─ notifications_module_test.dart          # tests that the module registers Notifications with the Registry
         ├─ notifications_config_test.dart          # tests the default channel, small icon, sound, and exact alarm policy
         ├─ notification_failure_mapper_test.dart   # tests mapping plugin errors to Failure notifications, permission, or unavailable
         ├─ notification_channels_test.dart         # tests that the Android channels are defined at startup
         ├─ timezone_resolver_test.dart             # tests that tz.local follows the device time zone, not UTC
         ├─ notification_payload_test.dart          # tests the typed JSON payload: route and argument round trip, plus the size limit
         ├─ notification_id_allocator_test.dart     # tests that ids are stable per string key and do not collide
         ├─ notification_tap_hub_test.dart          # tests that foreground taps, background taps, and launchTap are merged
         ├─ notification_permission_flow_test.dart  # tests the permission request through Permissions, including when the contract is not registered
         ├─ reminder_scheduler_test.dart            # tests that rescheduling is idempotent per key
         └─ notifications_contract_test.dart        # runs the Notifications contract suite from kiln_testing against this implementation
```

### image_picker

```text
extensions/image_picker/
├─ extension.yaml                           # manifest: provides: media · category: media · exclusive · prompts: max_bytes, allowed_types · ios: plist · macos: device.camera
├─ README.md                                # introduction to the image_picker extension: what it does, how to install it, and usage examples
├─ CHANGELOG.md                             # changelog of the image_picker extension per version
├─ docs/                                    # image_picker extension documentation for users and contributors
│  ├─ image-picker.md                       # guide to using MediaPicker to pick images from the camera and gallery
│  ├─ upload-flow.md                        # explains the flow from PickedImage to FileStorage without importing a backend
│  └─ platform-notes.md                     # platform notes: activity destroyed on Android, HEIC on iOS, web limits
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick: templates rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and template variables
   └─ __brick__/                            # template contents rendered into the application project
      ├─ lib/extensions/image_picker/               # image_picker extension code rendered into the application lib
      │  ├─ image_picker_module.dart                # registers the MediaPicker implementation with the Registry
      │  ├─ device_media_picker.dart                # MediaPicker contract implementation on top of ImagePickerGateway
      │  ├─ image_picker_gateway.dart               # wraps the image_picker plugin so it can be faked in tests
      │  ├─ media_picker_config.dart                # typed configuration: default dimensions and quality, maximum size, allowed types
      │  ├─ media_failure_mapper.dart               # maps PlatformException errors to Failure(permission, unavailable, or cancelled)
      │  ├─ mime_sniffer.dart                       # detects jpeg, png, webp, heic, gif from the leading bytes, not the plugin mimeType
      │  ├─ image_validator.dart                    # validates image size and type, failing with Failure(validation)
      │  ├─ camera_permission_precheck.dart         # checks the Permissions contract first (readOrNull) so denials are clear
      │  ├─ lost_data_recovery.dart                 # recovers the picked result when the Android activity is destroyed
      │  ├─ picked_image_x.dart                     # extensions on PickedImage: toImageProvider and a readable size ("1,2 MB")
      │  ├─ picked_image_upload_adapter.dart        # converts PickedImage into FileStorage input, both types from kiln_core
      │  └─ widgets/                                # ready-made widgets for picking images
      │     ├─ image_source_sheet.dart              # bottom sheet for choosing the image source, camera or gallery
      │     └─ avatar_picker.dart                   # round avatar that can be replaced, showing Failures in a friendly way
      └─ test/extensions/image_picker/              # tests that are also rendered into the app and run there
         ├─ device_media_picker_test.dart           # tests that an image pick from the fake gateway becomes a MediaPicker result
         ├─ image_picker_module_test.dart           # tests that the module registers MediaPicker with the Registry
         ├─ media_picker_config_test.dart           # tests the default dimensions, quality, maximum size, and types
         ├─ media_failure_mapper_test.dart          # tests mapping PlatformException to Failure permission, unavailable, or cancelled
         ├─ mime_sniffer_test.dart                  # tests type detection from the leading bytes: jpeg, png, webp, heic, gif
         ├─ image_validator_test.dart               # tests that an invalid size or type yields Failure(validation)
         ├─ camera_permission_precheck_test.dart    # tests the camera permission check through Permissions before opening the camera
         ├─ lost_data_recovery_test.dart            # tests recovering the picked result after the Android activity is destroyed
         ├─ picked_image_x_test.dart                # tests toImageProvider and the readable size format ("1,2 MB")
         ├─ picked_image_upload_adapter_test.dart   # tests that PickedImage is converted into correct FileStorage input
         ├─ image_source_sheet_test.dart            # tests the bottom sheet choosing the camera or gallery source
         ├─ avatar_picker_test.dart                 # tests that the avatar changes after picking and Failures are shown in a friendly way
         └─ media_picker_contract_test.dart         # runs the MediaPicker contract suite from kiln_testing against this implementation
```

