### crash_report

The roadmap still parks this extension because no vendor has been chosen yet, so
this picture uses **Sentry as an example** behind `crash_report_gateway.dart`.
Swapping vendors means swapping one gateway, not the layers above it.

```text
extensions/crash_report/
├─ extension.yaml                            # manifest: provides: crash_reporter · category: crash_reporting · exclusive · prompts: dsn (secret), sample_rate · android: INTERNET
├─ README.md                                 # introduction to the extension: what it does, how to install it, and configuration options
├─ CHANGELOG.md                              # change history of the extension per version
├─ docs/                                     # crash reporting, vendor selection, symbols, and privacy documentation
│  ├─ crash-reporting.md                     # overview of crash reporting and the decorator layers above the gateway
│  ├─ choosing-a-vendor.md                   # criteria for choosing a vendor and how to swap the gateway
│  ├─ symbols-and-obfuscation.md             # how to upload symbols in CI and use --split-debug-info
│  └─ privacy-and-consent.md                 # privacy guide: user consent through ConsentController and PII filtering
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                    # Mason brick: templates rendered into the user app
   ├─ brick.yaml                             # Mason brick metadata: name, version, and variables from prompts
   └─ __brick__/                             # template contents copied into the user app
      ├─ lib/extensions/crash_report/               # extension runtime code in the user app
      │  ├─ crash_report_module.dart                # registers CrashReporter together with its decorators with the Registry
      │  ├─ crash_report_config.dart                # typed configuration: dsn, environment from AppFlavor, release, sample rate
      │  ├─ crash_report_gateway.dart               # vendor interface that can be faked in tests: captureError, addBreadcrumb, setUser, setContext
      │  ├─ sentry_crash_gateway.dart               # wraps sentry_flutter as a sample SdkCrashGateway so it can be faked in tests
      │  ├─ crash_report_failure_mapper.dart        # maps vendor initialization errors to Failure(unavailable), the app can still start
      │  ├─ safe_crash_reporter.dart                # decorator: never throws, gateway failures are logged once to Logger
      │  ├─ consent_gate_crash_reporter.dart        # decorator: reports before ConsentController consent are dropped or held per configuration
      │  ├─ pii_scrubbing_crash_reporter.dart       # decorator: applies PiiRedactor to messages, breadcrumbs, context, and user identity
      │  ├─ failure_classifier.dart                 # marks expected Failures (network, cancelled, validation) so they are not reported
      │  ├─ error_deduplicator.dart                 # rate-limits repeated identical errors, using the Clock
      │  ├─ release_info.dart                       # provides the version and build number for grouping reports
      │  ├─ breadcrumb_recorder.dart                # records navigation, connectivity, and sessions as breadcrumbs through the contracts (readOrNull)
      │  ├─ http_breadcrumb_middleware.dart         # contributes: http.interceptors (when: [http_pipeline]), without bodies and sensitive headers
      │  └─ crash_test_trigger.dart                 # test button to send a crash, non-production flavors only
      └─ test/extensions/crash_report/              # tests that run in the user app for this extension code
         ├─ crash_report_module_test.dart           # tests that the module registers the decorator-wrapped CrashReporter with the Registry
         ├─ crash_report_config_test.dart           # tests reading dsn, environment from AppFlavor, release, and sample rate
         ├─ crash_report_failure_mapper_test.dart   # tests that vendor initialization errors become Failure(unavailable)
         ├─ safe_crash_reporter_test.dart           # tests that gateway failures are not thrown and are logged once to Logger
         ├─ consent_gate_crash_reporter_test.dart   # tests that reports before consent are dropped or held per configuration
         ├─ pii_scrubbing_crash_reporter_test.dart  # tests that PiiRedactor is applied to messages, breadcrumbs, context, and user identity
         ├─ failure_classifier_test.dart            # tests that network, cancelled, and validation Failures are not reported as crashes
         ├─ error_deduplicator_test.dart            # tests that repeated identical errors are rate-limited with a fake Clock
         ├─ release_info_test.dart                  # tests that the version and build number are read for grouping reports
         ├─ breadcrumb_recorder_test.dart           # tests breadcrumb recording of navigation, connectivity, and sessions through the contracts
         ├─ http_breadcrumb_middleware_test.dart    # tests that HTTP breadcrumbs carry no bodies and no sensitive headers
         ├─ crash_test_trigger_test.dart            # tests that the crash test button appears only in non-production flavors
         └─ crash_reporter_contract_test.dart       # runs the CrashReporter contract suite from kiln_testing against this implementation
```

### ci

```text
extensions/ci/
├─ extension.yaml                            # manifest: provides: ci · category: ci · exclusive · prompts: flutter_version (default stable), build_artifacts (bool), coverage_threshold
├─ README.md                                 # introduction to the extension: what it does, how to install it, and configuration options
├─ CHANGELOG.md                              # change history of the extension per version
├─ docs/                                     # CI documentation: how the workflow runs, the secrets it needs, and symbol upload
│  ├─ ci.md                                  # CI workflow guide: format, analyze, test, and the coverage threshold
│  ├─ required-secrets.md                    # names of the secrets the workflow needs and how to create them
│  └─ symbols-and-release-notes.md           # steps to upload crash_report symbols when installed, and this extension's limits
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                    # Mason brick: templates rendered into the user app
   ├─ brick.yaml                             # Mason brick metadata: name, version, and variables from prompts
   └─ __brick__/                             # template contents copied into the user app
      ├─ .github/                            # GitHub configuration in the user app: workflows, dependabot, PR template
      │  ├─ workflows/                       # GitHub Actions workflows run in CI
      │  │  ├─ ci.yaml                       # runs format, analyze, and test with a coverage threshold
      │  │  ├─ build.yaml                    # builds apk and web as artifacts, ios --no-codesign on the macOS runner
      │  │  └─ kiln_doctor.yaml              # runs kiln doctor --json, fails when hashes, lockfiles, or registration are out of sync
      │  ├─ dependabot.yml                   # Dependabot configuration for pub and github-actions, weekly
      │  └─ PULL_REQUEST_TEMPLATE.md         # pull request description template filled in by contributors
      └─ test/extensions/ci/                 # tests that check the rendered CI workflows and configuration in the user app
         ├─ ci_workflow_test.dart            # tests that ci.yaml runs format, analyze, and test with a coverage threshold
         ├─ build_workflow_test.dart         # tests that build.yaml builds apk and web, and ios without codesign
         ├─ kiln_doctor_workflow_test.dart   # tests that kiln_doctor.yaml runs kiln doctor --json and fails when out of sync
         └─ dependabot_config_test.dart      # tests that dependabot.yml watches pub and github-actions weekly
```

### codegen

This extension is the only one that needs hooks as a core part of its flow (running
`build_runner`). The roadmap parks it until its generated-code contract is clear;
this picture proposes `json_serializable` and `freezed` as the starting options.

```text
extensions/codegen/
├─ extension.yaml                            # manifest: provides: codegen · category: codegen · exclusive · prompts: generators (multi-select) · deps: json_annotation, freezed_annotation
├─ README.md                                 # introduction to the extension: what it does, how to install it, and configuration options
├─ CHANGELOG.md                              # change history of the extension per version
├─ docs/                                     # codegen documentation: the build_runner flow, JSON models, and troubleshooting
│  ├─ codegen.md                             # codegen overview and how to use the selected generators
│  ├─ build-runner-workflow.md               # how to build once, watch mode, and what gets committed
│  ├─ json-models.md                         # how to write JSON models with json_serializable and freezed
│  └─ troubleshooting.md                     # resolving output conflicts and analyzer version issues
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                    # Mason brick: templates rendered into the user app
   ├─ brick.yaml                             # Mason brick metadata: name, version, and variables from prompts
   ├─ hooks/                                 # Mason hooks that run before and after rendering
   │  ├─ pubspec.yaml                        # package dependencies for the pre_gen and post_gen hooks
   │  ├─ pre_gen.dart                        # checks the user's build.yaml in the target folder before rendering
   │  └─ post_gen.dart                       # runs build_runner build --delete-conflicting-outputs, failure only warns
   └─ __brick__/                             # template contents copied into the user app
      ├─ build.yaml                          # sets json_serializable options: explicit_to_json and field_rename snake
      ├─ lib/extensions/codegen/             # extension code in the user app: converters and a sample model
      │  ├─ json_converters.dart             # converts epoch DateTime, Uri, and Duration via @JsonKey
      │  └─ example/                         # sample model together with its generated output
      │     ├─ example_model.dart            # defines the sample model with @freezed and @JsonSerializable
      │     ├─ example_model.g.dart          # generated by build_runner, do not edit
      │     └─ example_model.freezed.dart    # generated by build_runner, do not edit
      └─ test/extensions/codegen/            # tests that check the converters and sample model in the user app
         ├─ json_converters_test.dart        # tests converting epoch DateTime, Uri, and Duration to and from JSON
         └─ example_model_test.dart          # tests the JSON round trip on the sample model
```

