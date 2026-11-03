## Extensions: navigation and UI

Four extensions that change what the user sees and moves through. All of them attach
to seams in `app_basic` (`AppThemeConfig`, `AppLocalizationsConfig`, `RouterConfig`)
through the Registry, so `app.dart` does not need to be edited.

### go_router

```text
extensions/go_router/                       # navigation extension: router, guards, and mapping links to routes
├─ extension.yaml                           # manifest: provides: navigation · category: navigation · exclusive · slot: router.routes
├─ README.md                                # overview, how to install, and usage examples for the go_router extension
├─ CHANGELOG.md                             # change history of the go_router extension per version
├─ docs/                                    # go_router documentation for application developers
│  ├─ navigation.md                         # navigation guide and how to add routes through the router.routes slot
│  ├─ route-guards.md                       # guide to session-based redirects and guard ordering
│  └─ deep-links-and-routing.md             # how links from deep_link become route locations
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into extension code in the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and prompt variables
   └─ __brick__/                            # template files rendered into the user app
      ├─ lib/extensions/go_router/          # go_router extension runtime code in the user app
      │  ├─ go_router_module.dart            # registers the navigation router and the router.routes slot with the Registry
      │  ├─ app_router.dart                  # builds the GoRouter from routes, guards, and router configuration
      │  ├─ app_routes.dart                  # path and route name constants
      │  ├─ router_config.dart               # typed configuration: initialLocation, diagnostic logging, errorBuilder
      │  ├─ route_slot.dart                  # receives AppRoute from the router.routes slot and turns it into a GoRoute
      │  ├─ route_guard.dart                 # RouteGuard interface, guards are composed in order
      │  ├─ auth_redirect.dart               # session redirect: signed out to /sign-in, signed in away from /sign-in
      │  ├─ session_refresh_listenable.dart  # turns SessionController.changes into the router refreshListenable
      │  ├─ deep_link_route_mapper.dart      # maps a Uri from the DeepLinks contract to a route location (readOrNull)
      │  ├─ notification_route_mapper.dart   # maps a NotificationTap payload to a route location (readOrNull)
      │  ├─ navigation_observer.dart         # logs to AppLogger and sends the screen to Analytics (readOrNull)
      │  ├─ not_found_page.dart              # shows the page for unknown routes
      │  ├─ shell_scaffold.dart              # ShellRoute with bottom navigation, containing sample tabs
      │  └─ route_transitions.dart           # sets page transitions per platform
      └─ test/extensions/go_router/         # go_router extension tests that are also generated into the user app
         ├─ app_router_test.dart              # tests building the GoRouter from routes, guards, and configuration
         ├─ go_router_module_test.dart        # tests that the module registers the router and the router.routes slot with the Registry
         ├─ app_routes_test.dart              # tests that no path or route name is duplicated
         ├─ route_slot_test.dart              # tests that AppRoute from the router.routes slot becomes a GoRoute
         ├─ route_guard_test.dart             # tests that guards run in composition order
         ├─ auth_redirect_test.dart           # tests redirecting to /sign-in when signed out and away from it when signed in
         ├─ session_refresh_listenable_test.dart  # tests that SessionController changes trigger the refreshListenable
         ├─ deep_link_route_mapper_test.dart  # tests mapping a Uri from DeepLinks to a route location
         ├─ notification_route_mapper_test.dart  # tests mapping a NotificationTap payload to a route location
         ├─ navigation_observer_test.dart     # tests that navigation is logged to AppLogger and the screen is sent to Analytics
         ├─ not_found_page_test.dart          # tests that an unknown route shows the not found page
         └─ shell_scaffold_test.dart          # tests that the ShellRoute shows bottom navigation and switches tabs
```

### deep_link

```text
extensions/deep_link/                       # deep link extension: incoming links, validation, and outgoing link builder
├─ extension.yaml                           # manifest: provides: deep_links · prompts: scheme, hosts (optional) · android: url_schemes, app_links · ios: url_schemes, associated_domains
├─ README.md                                # overview, how to install, and configuration of the deep_link extension
├─ CHANGELOG.md                             # change history of the deep_link extension per version
├─ docs/                                    # deep_link documentation for application developers
│  ├─ deep-links.md                         # how deep links work and how they are configured
│  ├─ universal-links.md                    # guide to assetlinks.json and apple-app-site-association for universal links
│  └─ testing-links.md                      # how to test links with adb shell am start and xcrun simctl openurl
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into extension code in the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and prompt variables
   └─ __brick__/                            # template files rendered into the user app
      ├─ lib/extensions/deep_link/          # deep_link extension runtime code in the user app
      │  ├─ deep_link_module.dart            # registers the DeepLinks implementation with the Registry
      │  ├─ device_deep_links.dart           # DeepLinks implementation that reads incoming links through the gateway
      │  ├─ deep_link_gateway.dart           # wraps the link plugin behind an interface so it can be faked in tests
      │  ├─ app_links_gateway.dart           # gateway implementation that wraps the app_links plugin so it can be faked
      │  ├─ deep_link_config.dart            # typed configuration: scheme, allowed hosts, permitted path list
      │  ├─ deep_link_failure_mapper.dart    # maps plugin errors to Failure(deep_link)
      │  ├─ link_allowlist.dart              # rejects unknown schemes and hosts before they reach the router
      │  ├─ link_normalizer.dart             # normalizes links: lowercase, drop tracking parameters, tidy the path
      │  ├─ link_deduplicator.dart           # ignores identical links within a short window, timed by the Clock
      │  ├─ pending_link_buffer.dart         # buffers links that arrive before the listener is ready, replayed once
      │  └─ app_link_builder.dart            # builds outgoing links (share, email) with the project scheme
      └─ test/extensions/deep_link/         # deep_link extension tests that are also generated into the user app
         ├─ device_deep_links_test.dart         # tests that incoming links from the gateway are passed through DeepLinks
         ├─ deep_link_module_test.dart          # tests that the module registers DeepLinks with the Registry
         ├─ deep_link_config_test.dart          # tests building the configuration from scheme, hosts, and path list
         ├─ deep_link_failure_mapper_test.dart  # tests that plugin errors are mapped to Failure(deep_link)
         ├─ link_allowlist_test.dart            # tests that unknown schemes and hosts are rejected
         ├─ link_normalizer_test.dart           # tests lowercasing, tracking parameter removal, and path tidying
         ├─ link_deduplicator_test.dart         # tests that identical links are ignored within the Clock time window
         ├─ pending_link_buffer_test.dart       # tests that links arriving before the listener is ready are replayed once
         ├─ app_link_builder_test.dart          # tests building outgoing links with the project scheme
         └─ deep_links_contract_test.dart       # runs the DeepLinks contract suite from kiln_testing against this implementation
```

### theme

```text
extensions/theme/                           # app theme extension: colors, typography, design tokens, and light or dark mode
├─ extension.yaml                           # manifest: provides: theme · category: theme · exclusive · prompts: seed_color, font_family, corner_radius
├─ README.md                                # overview, how to install, and usage examples for the theme extension
├─ CHANGELOG.md                             # change history of the theme extension per version
├─ docs/                                    # theme documentation for application developers
│  ├─ theme.md                              # theme overview, configuration, and light or dark mode
│  ├─ design-tokens.md                      # design token guide: colors, spacing, radius, and typography
│  └─ rebranding.md                         # how to change the seed color without touching features
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into extension code in the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and prompt variables
   └─ __brick__/                            # template files rendered into the user app
      ├─ lib/extensions/theme/              # theme extension runtime code in the user app
      │  ├─ theme_module.dart                # registers AppThemeConfig and ThemeModeController with the Registry
      │  ├─ brand_theme.dart                 # assembles light and dark ThemeData from the color scheme, text, and components
      │  ├─ theme_config.dart                # typed configuration: seed color, font, radius, density
      │  ├─ color_schemes.dart               # builds light and dark ColorSchemes from the seed, including high contrast
      │  ├─ text_styles.dart                 # composes the app typography scale
      │  ├─ component_themes.dart            # styles component themes: AppBar, buttons, inputs, cards, dialogs, SnackBar, NavigationBar
      │  ├─ design_tokens.dart               # defines AppSpacing and AppRadius as ThemeExtensions
      │  ├─ semantic_colors.dart             # defines success, warning, and info colors as a ThemeExtension
      │  ├─ system_ui_style.dart             # sets status bar and navigation bar styles according to brightness
      │  ├─ theme_mode_controller.dart       # holds the mutable ThemeMode and notifies AppShell
      │  ├─ theme_mode_store.dart            # persists the mode choice through Storage when installed (readOrNull)
      │  ├─ theme_context_x.dart             # shortcut access via context.colors, context.spacing, and context.semantic
      │  └─ widgets/                         # ready-made widgets for changing the theme
      │     └─ theme_mode_switcher.dart      # shows the System, Light, and Dark options
      └─ test/extensions/theme/             # theme extension tests that are also generated into the user app
         ├─ brand_theme_test.dart             # tests that light and dark ThemeData are built from the configuration
         ├─ theme_module_test.dart            # tests that the module registers the theme configuration with the Registry
         ├─ theme_config_test.dart            # tests the seed color, font, radius, and density values in the configuration
         ├─ color_schemes_test.dart           # tests the light, dark, and high contrast ColorSchemes from the seed
         ├─ component_themes_test.dart        # tests the AppBar, button, input, card, dialog, SnackBar, and NavigationBar themes
         ├─ design_tokens_test.dart           # tests the AppSpacing and AppRadius values as ThemeExtensions
         ├─ semantic_colors_test.dart         # tests the success, warning, and info colors as a ThemeExtension
         ├─ theme_mode_controller_test.dart   # tests that changing the ThemeMode notifies listeners
         ├─ theme_mode_store_test.dart        # tests persisting the mode choice through Storage and behavior without Storage
         ├─ theme_mode_switcher_test.dart     # tests that choosing System, Light, or Dark changes the ThemeMode
         ├─ contrast_test.dart                # tests the contrast ratio of text against its background
         └─ theme_golden_test.dart            # tests the light and dark color swatches against the golden
```

### l10n

```text
extensions/l10n/                            # localization extension: locale, messages, plurals, and locale-aware formatting
├─ extension.yaml                           # manifest: provides: l10n · category: l10n · exclusive · prompts: locales, fallback_locale · dependency: flutter_localizations (sdk), intl
├─ README.md                                # overview, how to install, and usage examples for the l10n extension
├─ CHANGELOG.md                             # change history of the l10n extension per version
├─ docs/                                    # l10n documentation for application developers
│  ├─ l10n.md                               # l10n overview, locale selection, and how to use strings
│  ├─ adding-a-language.md                  # steps for adding a language together with its translations
│  └─ formatting.md                         # guide to date, number, currency, and plural formatting
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
│  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
│  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into extension code in the user app
   ├─ brick.yaml                            # Mason brick metadata: name, version, and prompt variables
   └─ __brick__/                            # template files rendered into the user app
      ├─ lib/extensions/l10n/               # l10n extension runtime code in the user app
      │  ├─ l10n_module.dart                 # registers AppLocalizationsConfig and LocaleController with the Registry
      │  ├─ l10n_delegate.dart               # creates the LocalizationsDelegate that loads strings for the active locale
      │  ├─ l10n_strings.dart                # holds the interface text for each supported language
      │  ├─ l10n_config.dart                 # typed configuration: supported locales, fallback locale
      │  ├─ locale_resolution.dart           # maps a device locale to a supported locale (id_ID to id)
      │  ├─ locale_controller.dart           # holds the mutable locale, null means follow the system
      │  ├─ locale_store.dart                # persists the locale choice through Storage when installed (readOrNull)
      │  ├─ message_formatter.dart           # formats messages: named placeholders, brace escaping
      │  ├─ plural_rules.dart                # picks the plural form: one and other for English, a single form for Indonesian
      │  ├─ locale_formatters.dart           # formats dates, numbers, and currencies by locale
      │  ├─ failure_messages.dart            # provides a friendly message per FailureCode, used by failure_presenter in app_basic
      │  └─ widgets/                         # ready-made widgets for choosing a language
      │     └─ language_switcher.dart        # shows the language options for changing the app locale
      └─ test/extensions/l10n/              # l10n extension tests that are also generated into the user app
         ├─ l10n_test.dart                    # tests that the LocalizationsDelegate loads strings for the locale
         ├─ l10n_module_test.dart             # tests that the module registers the localization configuration with the Registry
         ├─ l10n_config_test.dart             # tests the supported and fallback locales in the configuration
         ├─ locale_resolution_test.dart       # tests mapping a device locale to a supported locale (id_ID to id)
         ├─ locale_controller_test.dart       # tests that the locale is mutable and null means follow the system
         ├─ locale_store_test.dart            # tests persisting the locale choice through Storage and behavior without Storage
         ├─ message_formatter_test.dart       # tests named placeholders and brace escaping
         ├─ plural_rules_test.dart            # tests the one and other plural forms (English) and the single form (Indonesian)
         ├─ locale_formatters_test.dart       # tests date, number, and currency formatting by locale
         ├─ failure_messages_test.dart        # tests that every FailureCode has a friendly message
         ├─ language_switcher_test.dart       # tests that choosing a language changes the app locale
         └─ l10n_coverage_test.dart           # tests that every key in the main language exists in all other languages
```

