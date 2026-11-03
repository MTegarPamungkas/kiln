# Extension catalog

This catalog is generated from extension manifests by
`tool/gen_catalog_docs.dart`. Do not edit it manually.

| ID | Name | Version | Category | Tier | Provides |
| --- | --- | --- | --- | --- | --- |
| `analytics` | Analytics | 0.1.1 | analytics | official | `analytics` |
| `appwrite` | Appwrite | 0.1.2 | auth | official | `auth`, `remote_database`, `file_storage` |
| `biometric` | Biometric | 0.1.4 | security | official | `biometric` |
| `bloc` | Bloc state management | 0.1.3 | state | official | `state_bloc` |
| `connectivity` | Connectivity | 0.1.1 | connectivity | official | `connectivity` |
| `deep_link` | Deep links | 0.1.2 | deep_link | official | `deep_links` |
| `dio` | Dio HTTP client | 0.2.4 | network | official | `http_client`, `http_pipeline` |
| `env` | Environment | 0.1.1 | config | official | `env` |
| `firebase` | Firebase | 0.2.1 | auth | official | `auth`, `social_auth`, `remote_database`, `file_storage` |
| `flavors` | Flavors | 0.1.1 | flavor | official | `flavor` |
| `go_router` | GoRouter | 0.2.1 | navigation | official | `navigation` |
| `http_cache` | HTTP cache | 0.1.1 | network | official | `http_cache` |
| `http_retry` | HTTP retry | 0.1.1 | network | official |  |
| `image_picker` | Image picker | 0.1.1 | media | official | `media` |
| `l10n` | Localization | 0.1.5 | l10n | official | `l10n` |
| `local_db` | Local database | 0.1.1 | database | official | `local_db` |
| `logger` | Logger | 0.1.1 | logging | official | `logger` |
| `notifications` | Notifications | 0.1.4 | notifications | official | `notifications` |
| `permission` | Permission | 0.1.1 | platform | official | `permission` |
| `rest_auth` | REST auth | 0.1.2 | auth | official | `auth` |
| `riverpod` | Riverpod state management | 0.1.2 | state | official | `state_riverpod` |
| `secure_storage` | Secure storage | 0.1.1 | storage | official | `secure_storage` |
| `social_login` | Social login | 0.1.1 | social | official | `social_login` |
| `storage` | Key-value storage | 0.1.1 | storage | official | `storage` |
| `supabase` | Supabase | 0.1.2 | auth | official | `auth`, `social_auth`, `remote_database`, `file_storage` |
| `theme` | Theme | 0.1.1 | theme | official | `theme` |

## analytics

PostHog product analytics with consent gating and PII scrubbing.

- Provides: `analytics`
- Prompts: api_key, host
- Dependencies: `posthog_flutter: ^5.58.3`
- Platforms: android, ios, macos, web, windows, linux

## appwrite

Appwrite auth, remote database, and file storage backends.

- Provides: `auth`, `remote_database`, `file_storage`
- Prompts: endpoint, project_id, database_id, bucket_id
- Dependencies: `appwrite: ^28.2.0`, `http: ^1.6.0`, `shared_preferences: ^2.3.0`
- Platforms: android, ios, macos, web, windows, linux

## biometric

Biometric authentication, app lock, and protected storage.

- Provides: `biometric`
- Prompts: reason, grace_seconds, biometric_only
- Dependencies: `local_auth: ^3.0.2`
- Platforms: android, ios, macos

## bloc

State management with Bloc and Cubit.

- Provides: `state_bloc`
- Dependencies: `bloc: ^9.2.1`, `flutter_bloc: ^9.1.1`, `bloc_concurrency: ^0.3.0`, `rxdart: ^0.28.0`

## connectivity

Network status monitoring and an offline guard middleware.

- Provides: `connectivity`
- Prompts: probe_url, probe_interval, probe_timeout, debounce_ms
- Dependencies: `connectivity_plus: ^7.3.2`

## deep_link

Incoming deep links with allowlisting, normalization, and deduplication.

- Provides: `deep_links`
- Prompts: scheme, hosts, path_prefixes
- Dependencies: `app_links: ^7.2.2`
- Platforms: android, ios, macos, web, windows, linux

## dio

HTTP client and middleware pipeline built on dio.

- Provides: `http_client`, `http_pipeline`
- Prompts: base_url, connect_timeout, api_key_header, api_key_query, api_key_prefix
- Dependencies: `dio: ^5.11.1`
- Platforms: android, ios, macos, web, windows, linux

## env

Typed build-time configuration from --dart-define values.

- Provides: `env`
- Prompts: keys
- Platforms: android, ios, macos, web, windows, linux

## firebase

Firebase Auth, Firestore, and Cloud Storage behind Kiln contracts.

- Provides: `auth`, `social_auth`, `remote_database`, `file_storage`
- Prompts: options_source, firebase_options_path, emulator_host, use_emulator_in_development
- Dependencies: `firebase_core: ^5.1.0`, `firebase_auth: ^7.0.1`, `cloud_firestore: ^7.1.0`, `firebase_storage: ^14.0.1`
- Platforms: android, ios, macos, web, windows

## flavors

Dart-level app flavors, entry points, and launch configurations.

- Provides: `flavor`
- Prompts: flavors
- Platforms: android, ios, macos, web, windows, linux

## go_router

Declarative routing with route slots, guards, and deep link mapping.

- Provides: `navigation`
- Dependencies: `go_router: ^18.1.2`
- Platforms: android, ios, macos, web, windows, linux

## http_cache

Caches HTTP responses with TTL, ETag, and invalidation.

- Provides: `http_cache`
- Requires: `http_client`, `http_pipeline`
- Prompts: default_ttl_seconds, max_entries, stale_while_revalidate

## http_retry

Retries temporary HTTP failures with backoff and a retry budget.

- Requires: `http_client`, `http_pipeline`
- Prompts: max_attempts, initial_delay_ms, max_delay_ms, jitter

## image_picker

Camera and gallery image picking with validation and upload handoff.

- Provides: `media`
- Prompts: max_bytes, allowed_types
- Dependencies: `image_picker: ^1.2.4`
- Platforms: android, ios, macos, web, windows, linux

## l10n

ARB-based localizations with gen-l10n, locale selection, plurals, and formatting.

- Provides: `l10n`
- Prompts: locales, fallback_locale
- Dependencies: `flutter_localizations: {sdk: flutter}`, `intl: ^0.20.3`
- Platforms: android, ios, macos, web, windows, linux

## local_db

Offline-first document database backed by Sembast.

- Provides: `local_db`
- Dependencies: `sembast: ^3.9.0`, `sembast_web: ^2.4.6+1`, `path_provider: ^2.1.6`, `path: ^1.9.1`, `encrypt: ^5.0.3`
- Platforms: android, ios, macos, web, windows, linux

## logger

Structured application logging with redaction, rotating files, and crash breadcrumbs.

- Provides: `logger`
- Prompts: file_sink, http_logging
- Dependencies: `path_provider: ^2.1.6`
- Platforms: android, ios, macos, web, windows, linux

## notifications

Local notifications with channels, scheduling, and tap routing.

- Provides: `notifications`
- Prompts: default_channel, small_icon, exact_alarms
- Dependencies: `flutter_local_notifications: ^22.3.3`, `flutter_timezone: ^5.1.1`, `timezone: ^0.11.2`
- Platforms: android, ios, macos, web, windows, linux

## permission

Typed permission checks and requests with rationale flow.

- Provides: `permission`
- Prompts: kinds
- Dependencies: `permission_handler: ^13.0.2`
- Platforms: android, ios, macos, web, windows, linux

## rest_auth

Email and password authentication against a REST API.

- Provides: `auth`
- Requires: `http_client`, `secure_storage`
- Prompts: base_url, login_path, register_path, refresh_path, logout_path, me_path

## riverpod

State management with Riverpod providers and Notifier.

- Provides: `state_riverpod`
- Dependencies: `flutter_riverpod: ^3.4.3`

## secure_storage

Keychain and Keystore storage for secrets and tokens.

- Provides: `secure_storage`
- Dependencies: `flutter_secure_storage: ^11.2.0`
- Platforms: android, ios, macos, web, windows, linux

## social_login

Google and Apple credential sign-in for a social auth backend.

- Provides: `social_login`
- Requires: `social_auth`
- Prompts: google_server_client_id, google_ios_client_id, apple_service_id, apple_redirect_uri
- Dependencies: `google_sign_in: ^7.2.0`, `sign_in_with_apple: ^8.2.0`, `crypto: ^3.0.8`
- Platforms: android, ios, macos, web

## storage

Persistent key-value storage backed by shared_preferences.

- Provides: `storage`
- Dependencies: `shared_preferences: ^2.5.6`

## supabase

Supabase auth, PostgREST database, realtime, and storage for Kiln.

- Provides: `auth`, `social_auth`, `remote_database`, `file_storage`
- Prompts: url, anon_key, schema
- Dependencies: `supabase_flutter: ^2.18.3`
- Platforms: android, ios, macos, web, windows, linux

## theme

Brand color, typography, design tokens, and light or dark mode for Kiln apps.

- Provides: `theme`
- Prompts: seed_color, font_family, corner_radius, density
- Platforms: android, ios, macos, web, windows, linux
