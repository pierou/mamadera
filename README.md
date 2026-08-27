# 🍼 Mamadera

**Privacy-first newborn tracking app.** Track your baby's feedings, sleep, diaper changes, and health routines — all stored locally on your device, with sensitive notes encrypted at rest. No cloud, no telemetry, no tracking.

[![CI](https://github.com/pierou/mamadera/actions/workflows/ci.yml/badge.svg)](https://github.com/pierou/mamadera/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](.github/LICENSE)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 👶 **Baby profiles** | Manage multiple baby profiles with active profile selection; cascade-aware deletion of associated data |
| 🍼 **Feedings** | Track breastfeeding and bottle feedings with duration logging and optional notes |
| 😴 **Sleep** | Log naps and nighttime sleep sessions with start/end timestamps |
| 💩 **Diapers** | Record wet or dirty diaper changes at a glance |
| ❤️ **Health routines** | Track eye/face/nose cleaning, belly button care, Vitamin D (daily), and Vitamin K (every 30 days rolling interval) with reminder pills for overdue items |
| 🔔 **Reminders** | Periodic health reminders with dismissal cooldowns; supports daily, weekly, monthly, and custom intervals via sealed `ReminderFrequency` variants |
| 📜 **History** | Chronological event browser with filter by type, inline editing, and deletion support |
| ⚙️ **Settings & Menu** | Language selector (fr/en/es), theme mode toggle (light/dark/system), database reset, feedback screen with direct email/GitHub links |
| ✅ **Onboarding** | First-launch Terms of Service acceptance flow with localized markdown content; app access gated until accepted via router guards |
| 📝 **Patch notes** | Version-update changelog dialog on app upgrade, loaded from locale-specific JSON assets; opt-out preference supported |

---

## 🏗️ Architecture

This project follows [Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) principles:

```
lib/
├── core/                                  # Cross-cutting concerns (shared by all features)
│   ├── config/                            # App configuration (version, contact info)
│   ├── l10n/                              # Localization: ARB translations + generated classes
│   ├── providers/                         # Core Riverpod providers (DB, encryption, locale, theme)
│   ├── router.dart                        # go_router setup with shell navigator & route guards
│   ├── services/                          # Core infrastructure services
│   │   ├── encryption_service.dart        # AES-GCM encrypt/decrypt
│   │   ├── locale_service.dart            # Language preference persistence (JSON)
│   │   ├── theme_service.dart             # Theme mode persistence (JSON)
│   │   └── app_preferences_service.dart   # Generic preferences storage
│   ├── theme.dart                         # App-wide theming (Cupertino + Material)
│   ├── utils/                             # Shared utilities (markdown parser)
│   └── widgets/                           # Reusable UI components (dialog buttons, feedback)
├── data/local/                            # Database layer (Drift ORM, factory functions)
│   ├── app_db.dart                        # Drift table classes (source of truth for schema)
│   ├── database.dart                      # Database service singleton + migrations
│   ├── db_constants.dart                  # Table/column constant definitions
│   ├── schema.sql                         # Generated DDL reference from app_db.dart
│   └── tracking_event_mapper.dart         # DTO ↔ domain entity mapping
├── features/<module>/                     # Feature modules with internal Clean Architecture layers
│   ├── baby/                              # Baby profile management (CRUD, active selection)
│   │   ├── domain/repositories/           # Abstract repository interfaces
│   │   ├── data/repositories/             # Concrete implementations (injects DB + encryption)
│   │   └── presentation/screens/          # UI screens & Riverpod notifiers
│   ├── history/                           # Event browsing with filtering/edit/delete
│   ├── home/                              # Main tracking entry point (all event types)
│   ├── menu/                              # Settings hub: language, theme, DB reset
│   ├── onboarding/                        # First-launch terms acceptance flow
│   ├── patchnotes/                        # Version-update changelog dialog
│   └── reminders/                         # Periodic health reminder system
├── l10n/                                  # Localization files (ARB translations for fr/en/es)
├── shared/domain/entities/                # Global domain models & enums
│   ├── baby_profile.dart                  # Baby profile model (@freezed)
│   ├── tracking_event.dart                # Sealed class: FeedingEvent, SleepEvent, etc.
│   ├── tracking_enums.dart                # HealthSubtype, WasteType, HistoryFilter, etc.
│   ├── tracking_icons.dart                # Icon mappings per TrackingType
│   └── tracking_type.dart                 # Core enum: miam, sante, caca, dodo
├── shared/utils/                          # Cross-feature utility helpers
└── main.dart                              # App entry point & initialization
```

### State Management

- **Riverpod** for all state management (`StateNotifier` and `AsyncNotifier`)
- No `Mixin`-based state management — explicit providers only
- **Core providers:** 8 singletons for database, encryption, locale, theme, active baby profile, app preferences, and tracking counter

### Database

- **Drift** (SQLite) with versioned migrations
- Schema source of truth: [`lib/data/local/app_db.dart`](lib/data/local/app_db.dart) (schema.sql is a generated reference)

### Routing & Navigation

- **go_router** with shell navigator for persistent bottom navigation bar
- Route guard chain: splash → terms acceptance check → patch notes (on version upgrade) → home screen

### Localization

- **ARB-based l10n** (`l10n.yaml`) with 3 supported locales: French (template), English, Spanish
- Date/time formatting via `intl` package per locale
- Localized assets: Terms of Service markdown files + patch notes JSON per language

---

## 🔒 Privacy & Security

| Principle | Implementation |
|-----------|----------------|
| **Local-first** | All data stored on-device via SQLite. No cloud sync by default. |
| **Encryption at rest** | Sensitive notes encrypted with AES-256-GCM before DB insertion. The database file itself is stored unencrypted on the device (field-level encryption only) |
| **Key storage** | Master key secured in platform-native keystore (iOS Keychain / Android Keystore) via `flutter_secure_storage`; memory fallback with warning on desktop without keyring |
| **No telemetry** | Zero analytics, tracking, or external network calls by default |
| **Minimal permissions** | No camera, no location — only what's strictly necessary |
| **Consent flow** | Terms of Service acceptance required before app access; patch notes opt-out preference after first dismissal. Persisted as local JSON preferences |
| **GDPR/CCPA/COPPA compliant** | Privacy policy included in-app. Open-source code audit welcome. |

### Encryption Flow

```
User input → AES-GCM encrypt (AES-256) → Store ciphertext in SQLite
                                       ↑
Master key stored securely ← flutter_secure_storage (Keychain / Keystore)
                              └─ 32-byte random key, 12-byte IV per encryption operation
```

### Data Lifecycle

- **Create:** Events encrypted at the repository layer before DB insertion
- **Read:** Decrypted on retrieval — UI only sees plaintext in memory during rendering
- **Update/Edit:** Re-encrypted with fresh IV on save
- **Delete:** Cascade-aware deletion (e.g., deleting a baby profile removes associated events)
- **Reset:** Database reset option in Settings physically deletes the SQLite file via `resetDatabase()` in the data layer

---

## 🚀 Getting Started

### Prerequisites

- Flutter `>=3.44.0` with Dart `>=3.4.0 <4.0.0`
- Android SDK or iOS tooling configured

### Installation

```bash
# Clone the repository
git clone https://github.com/pierou/mamadera.git
cd mamadera

# Install dependencies & generate code
make pub-get
make codegen

# Run the app
flutter run
```

### Localization Assets

The app ships with localized content for Terms of Service and version patch notes:

| Asset | Languages | Source |
|-------|-----------|--------|
| **Terms** (`assets/terms/`) | `terms_en.md`, `terms_es.md`, `terms_fr.md` | Markdown files bundled as assets |
| **Patch notes** (`assets/patch_notes/`) | `en.json`, `es.json`, `fr.json` | Generated from Conventional Commits via `make patch-notes VERSION=x.y.z DATE="2025-MM-DD" LANG=en`

### Makefile Commands

A `Makefile` is provided for local development, CI workflows, and store builds:

#### Development & CI

| Command | Description |
|---------|-------------|
| `make pub-get` | Install dependencies via `flutter pub get` |
| `make codegen` | Run `build_runner` for freezed/drift/json_serializable models |
| `make lint` | Static analysis (`flutter analyze --fatal-infos --fatal-warnings`) aligned with GitHub Actions |
| `make test` | Run unit & widget tests across `test/shared/`, `test/data/`, `test/features/`, `test/core/` with coverage |
| `make check-coverage` | Enforce ≥ 80% line coverage threshold via `lcov`; excludes generated/l10n files |
| `make ci` | Full pipeline: pub-get → lint → test → check-coverage |
| `make integration-test-simulator` | Run integration tests on connected iOS simulator/device |
| `make ci-integration` | Full integration test suite in VM mode (no device required) |
| `make clean` | Clean all generated artifacts (`flutter clean` + remove coverage/.dart_tool/build dirs) |

#### Build Targets

| Command | Description |
|---------|-------------|
| `make build-android` | Build release APK (F-Droid / sideloading) |
| `make build-aab` | Build App Bundle for Google Play Store (required since Feb 2021) |
| `make build-ipa` | Build unsigned IPA archive — use Xcode "Product → Archive" to sign and distribute via App Store |

#### Security Audits

| Command | Description |
|---------|-------------|
| `make audit-trivy` | Scan dependencies for HIGH/CRITICAL vulnerabilities via [Trivy](https://github.com/aquasecurity/trivy) |
| `make audit-gitleaks` | Detect leaked secrets in git history via [Gitleaks](https://github.com/gitleaks/gitleaks) |

#### Asset Generation

| Command | Description |
|---------|-------------|
| `make splash-create` | Regenerate native splash screen assets from pubspec.yaml config |
| `make patch-notes VERSION=x.y.z DATE="2025-..." LANG=en OUTPUT_DIR=assets/patch_notes` | Generate changelog JSON from Conventional Commits via Python script |

#### UI Validation

| Command | Description |
|---------|-------------|
| `make check-ui` | Validate no hardcoded colors, dark mode compliance, and font size usage across presentation code |

---

## 🧪 Testing

Tests are organized following the architecture rules, with coverage targets on domain/data layers at ≥ 80% line coverage.

### Unit & Widget Tests (~107 files)

```
test/
├── main_test.dart                   # App entry point tests
├── widget_test.dart                 # Basic widget smoke test
├── analysis_options.yaml            # Test-specific lint rules
├── core/                            # Core layer coverage (17+ files)
│   ├── config/app_config_test.dart  # AppConfig version/contact constants
│   ├── l10n/date_localization_test.dart  # Locale-aware date formatting tests
│   ├── providers/                   # Provider tests: locale, theme, active_baby, prefs, tracking_counter
│   ├── router_test.dart             # Route guard chain & redirect logic
│   ├── services/                    # Service unit tests + mocks (encryption, locale, theme, preferences)
│   ├── theme_test.dart              # Theme mode switching & color scheme validation
│   ├── utils/markdown_parser_test.dart  # Markdown rendering edge cases
│   └── widgets/                     # Dialog buttons, show_feedback UI tests
├── data/                            # Data layer tests (4 files)
│   ├── local/app_db_test.dart       # Drift table/model CRUD operations
│   ├── local/database_test.dart     # Database singleton, migration logic
│   └── repositories/tracking_repository_impl_test.dart  # Repo + encryption round-trip (+ mocks)
├── presentation/providers/          # Notifier/provider tests (5 files)
│   ├── filter_notifier_test.dart    # History filter state machine
│   ├── history_notifier_test.dart   # Event loading/pagination (+ mocks)
│   └── track_notifier_test.dart     # Insert flow + dialog state (+ mocks)
├── shared/domain/entities/          # Entity model tests (10 files)
│   └── [baby_profile, caca_color, edit_result, health_subtype, pipi_color,
           tracking_enums, event color db value, history_filter, icons, type, waste_type]
└── features/<module>/               # Feature-specific full-stack tests (~42 files)
    ├── baby/data/repositories/      # Baby profile CRUD + cascade delete repo impl
    ├── home/domain/, data/, presentation/screens/, providers/, widgets/  # Full coverage
    ├── history/data/repositories/   # History repo: update/delete/edit operations
    ├── menu/data/repositories/      # Menu preferences persistence tests
    ├── onboarding/presentation/widgets/# Terms acceptance dialog + localized content rendering
    ├── patchnotes/presentation/     # Patch notes UI display & opt-out logic
    └── reminders/domain/, data/, presentation/  # Reminder frequency variants, cooldown tracking
```

Run the test suite:

```bash
# Unit + widget tests with coverage collection (mirrors CI)
make test

# Full pipeline including linting and coverage threshold check
make ci
```

### Integration Tests

Integration tests live in `integration_test/` and validate full app flows using real widgets, providers, and routing:

```
integration_test/
├── test_utils.dart                    # Shared helpers: pumpMamadera(), TestKeys, finders
├── onboarding_flow_test.dart          # First-launch terms acceptance → home screen flow
├── feeding_tracking_flow_test.dart    # Tap track buttons → dialog overlays → cancel dismiss
├── history_flow_test.dart             # History tab navigation + empty state rendering
├── baby_profile_flow_test.dart        # Menu tab BabyProfileSection CRUD + cross-tab preservation
├── navigation_flow_test.dart          # Sequential tab switching, overlay dismissal, rapid nav settling
├── driver_integration_test.dart       # Flutter Driver-based automation for end-to-end flow validation
└── rendering_validation_test.dart     # Full-screen layout checks, SafeArea insets, black bar detection
```

**Key patterns:**

- **`pumpMamadera(tester)`** — Pumps the real `MyApp` with configurable provider overrides (accepted terms, in-memory DB, English locale). Use this instead of `app.main()` to control app state.
- **Provider override pattern** — Override notifiers synchronously so redirect callbacks resolve immediately without async delays. See `test_utils.dart` for the dynamic override list builder.
- **Semantic keys** — All track buttons (`track-miam`, `track-sante`, etc.) and bottom nav tabs have semantic keys defined in the `TestKeys` class, used by widget finders for reliable test selectors.
- **In-memory database** — Tests use an in-memory Drift instance so no persistent state leaks between tests.

Run integration tests on a connected simulator or device:

```bash
# Integration Test API (recommended, runs in VM):
make integration-test-simulator

# Full CI suite (no device required):
make ci-integration
```

---

## 📦 Dependencies

### Production

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` / `riverpod` | State management |
| `drift` + `sqflite_common_ffi` | Local SQLite database (Drift ORM with FFI for desktop) |
| `encrypt` | AES-GCM encryption logic |
| `flutter_secure_storage` | Platform-native key storage (Keychain/Keystore) |
| `go_router` | Declarative navigation with shell navigator & deep linking |
| `freezed_annotation` / `json_annotation` | Code generation: sealed classes, copyWith, serialization |
| `logger` | Structured logging (no `print()` — lint rule enforced) |
| `cupertino_icons` | iOS-style icons for Cupertino widgets |
| `flutter_localizations` | Framework-level localization infrastructure |
| `intl` | Date/time/number formatting per locale |
| `flutter_native_splash` | Native splash screen generation (Android drawables + iOS launch images) |
| `markdown` | Markdown rendering for Terms of Service and patch notes content |
| `package_info_plus` | Runtime app version reading for update detection & patch note triggers |
| `path_provider` | File system paths for JSON preference persistence files |
| `sqlcipher_flutter_libs` | SQLCipher native libraries (encrypted SQLite on mobile platforms) |
| `url_launcher` | Launch external URLs: email to support, GitHub issues link in feedback screen |

### Development & Build Tools

| Package | Purpose |
|---------|---------|
| `build_runner` | Code generation orchestrator (freezed, drift_dev, json_serializable) |
| `drift_dev` | Drift schema codegen (table classes, DDL) |
| `freezed` | Sealed class & union type code generator |
| `json_serializable` | `.fromJson()`/`.toJson()` boilerplate generation |
| `mockito` | Test mocking framework |
| `flutter_lints` | Lint ruleset (`flutter_lints recommended` + custom strict overrides in [`analysis_options.yaml`](analysis_options.yaml)) |
| `integration_test` / `flutter_driver` | Integration test API & driver-based E2E automation |
| `flutter_launcher_icons` | App icon generation from asset images |

---

## 🤝 Contributing

Contributions are welcome! Please read the following before submitting a PR:

- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Contributing Guidelines](.github/CONTRIBUTING.md)
- [Security Policy](.github/SECURITY.md)
- [Privacy Policy](.github/PRIVACY.md)

### Development Workflow

1. Create a feature branch from `develop`
2. Follow the clean architecture structure (`features/<module>/domain|data|presentation/`)
3. Write tests for domain logic and data layer (≥ 80% coverage required)
4. Use [Conventional Commits](https://www.conventionalcommits.org/) — commit messages feed into patch note generation via `make patch-notes`
5. Run `make ci` before pushing (lint + test + coverage check)
6. Open a PR targeting `develop`
7. For schema changes: run `make codegen` after modifying Drift table classes, then verify with `make lint`

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](.github/LICENSE) for details.

---

### 🤖 AI-Assisted Development

This project was developed using local instances of open weight models, under the supervision of responsible parents. No cloud models were used — everything stayed on-machine, in line with the privacy principles this application defends.

---

> Made with ❤️ for parents who value privacy as much as convenience.
