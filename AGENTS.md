# AGENTS.md — mamadera

AI agent instructions for the [mamadera](README.md) Flutter project. Read this file before making any changes to understand architecture, conventions, and privacy mandates.

## 🎯 Project Summary

Privacy-first newborn tracking app (feedings, sleep, diapers, health routines). **Offline-only, zero telemetry, data never leaves the device without explicit user consent.** iOS & Android targets; web/desktop only if explicitly requested.

See [README.md](README.md) for full feature list and architecture overview.

## 🔒 Privacy-First Mandates (NON NEGOTIABLE)

| Rule | Detail |
|------|--------|
| 🚫 **No analytics/telemetry** | Never suggest or add cloud crash reporting, analytics SDKs, or tracking services |
| 🚫 **No third-party data leakage** | No dependencies with hidden trackers; audit deps for privacy before adding |
| ✅ **Local-only storage** | All data stays on device. Export is manual: encrypted JSON or plain CSV only |
| ✅ **Minimal permissions** | None by default. Camera/storage only for explicit features + clear consent flow |
| ✅ **Encryption at rest** | Sensitive fields (notes, weight, allergies) encrypted with `flutter_secure_storage` before DB insert |
| ✅ **GDPR/CCPA/COPPA ready** | No data collection = compliance out-of-the-box. Privacy policy bundled in-app |

When suggesting features: always propose local/offline solutions first. If cloud is relevant, explicitly call out privacy implications and offer a local alternative.

## 🧱 Tech Stack

| Category | Package |
|----------|---------|
| Framework | Flutter 3.x / Dart 3.x (null-safe, records, pattern matching, sealed classes) |
| State Management | `flutter_riverpod` — `StateNotifier` + `AsyncNotifier` only. No mixin-based state mgmt |
| Routing | `go_router` |
| Local DB | `drift` (SQLite), DDL source of truth: [`lib/data/local/app_db.dart`](lib/data/local/app_db.dart) (schema.sql is a generated reference) |
| Encryption | `flutter_secure_storage` + AES-GCM via `encrypt` package |
| Models | `freezed` + `json_annotation` + `build_runner` codegen |
| Lints | `flutter_lints` (recommended) + custom strict rules in [`analysis_options.yaml`](analysis_options.yaml) |

## 🏗️ Architecture: Feature-First Clean Architecture

```
lib/
├── main.dart                              # Entry point, encryption init, ProviderScope root
├── core/                                  # Cross-cutting concerns (shared by all features)
│   ├── services/                          # Core infrastructure (EncryptionService etc.)
│   ├── providers/                         # Global Riverpod providers (DB + encryption singletons)
│   └── theme.dart                         # App-wide theming
├── data/local/                            # Database layer (Drift ORM, factory functions)
│   ├── schema.sql                         # DDL definitions — source of truth for tables
│   ├── app_db.dart                        # Drift table & query classes
│   └── database.dart                      # Database service singleton + migrations
├── shared/domain/entities/                # Global domain models and enums (e.g. TrackingType)
└── features/<module>/                     # Feature modules with internal Clean Architecture layers
    ├── domain/repositories/               # Abstract repository interface (pure Dart, no Flutter deps)
    ├── data/repositories/                 # Concrete implementation (injects DB + encryption)
    └── presentation/                      # UI screens, widgets, Riverpod providers & notifiers
```

### Key Architecture Rules

- **Domain layer**: pure logic, zero framework dependencies. Define `abstract class` repository interfaces here.
- **Data layer**: implement domain repositories. Inject `AppDatabase` + `EncryptionService`. Handle encryption/decryption before DB ops.
- **Presentation layer**: widgets + Riverpod notifiers that depend on repository providers only (never directly on DB).

### Repository Pattern Example

```dart
// features/home/domain/repositories/tracking_repository.dart
abstract class TrackingRepository {
  Future<List<TrackingEvent>> getEvents({DateTime? after, DateTime? before});
  Future<int> insertEvent(TrackingEvent event);
}

// features/home/data/repositories/tracking_repository_impl.dart
class TrackingRepositoryImpl implements TrackingRepository {
  final AppDatabase db;
  final EncryptionService encryption;
  // ... inject via constructor or provider
}
```

## 💻 Coding Conventions

### Dart/Flutter Style

- `final` / `const` everywhere possible
- Widgets > ~25 lines → extract to reusable sub-widgets
- Prefer `sealed class` for states/events (exhaustive switching)
- Naming: `camelCase` vars/functions, `PascalCase` classes/widgets, `snake_case` files/dirs
- Comments: `///` Dartdoc for all public members; comment business logic, skip trivial code
- Avoid magic strings/numbers → use `const` or `enum`
- Logging: `logger` package only — **never** `print()` (lint rule enforces this)

### State Management (Riverpod)

- Local mutable state → `StateNotifier`
- Async operations with loading/error states → `AsyncNotifier`
- Override providers in tests using `ProviderContainer(overrides: [...])`
- No global DI container (`get_it`) unless a single global singleton is genuinely needed

### Database (Drift)

- Schema source of truth: [`lib/data/local/schema.sql`](lib/data/local/schema.sql)
- Versioned migrations — always update migration logic when schema changes
- Encrypt sensitive columns before insert; decrypt on read in the repository layer

## 🛠️ Build & Test Commands

All commands available via [`Makefile`](Makefile):

| Command | Description |
|---------|-------------|
| `make codegen` | Run `build_runner` for freezed/drift/json_serializable models |
| `make pub-get` | Install dependencies |
| `make lint` | Run `flutter analyze --fatal-infos --fatal-warnings` |
| `make test` | Run all tests with coverage (`--coverage`) |
| `make check-coverage` | Verify ≥ 80% line coverage (uses `lcov`) |
| `make ci` | Full pipeline: pub-get → lint → test → coverage check |
| `make build-android` | Build release APK |
| `make clean` | Clean build artifacts |
| `make audit-trivy` | Security scan dependencies with Trivy (HIGH/CRITICAL) |
| `make audit-gitleaks` | Detect leaked secrets in git history with Gitleaks |

### CI Pipeline (GitHub Actions)

1. `flutter analyze --fatal-infos --fatal-warnings` — no warnings allowed
2. `flutter test ... --coverage` — tests with coverage collection
3. Coverage threshold: ≥ 80% for `domain/` and `data/` layers

### Codegen

After adding/modifying `freezed`, `json_serializable`, or `drift` models, run:
```bash
make codegen
```
Then run `make lint` to verify no unresolved imports remain.

## 🧪 Testing Strategy

| Layer | Test Type | Location |
|-------|-----------|----------|
| `domain/` | Unit tests (pure logic, no mocks needed) | `test/features/<module>/domain/` |
| `data/` | Unit tests with mocked DB + encryption service | `test/data/` |
| `presentation/` | Widget tests with ProviderContainer overrides | `test/presentation/`, `test/features/*/presentation/` |

- Use round numbers for synthetic data (10, 100) — keep fixtures simple and verifiable
- Mock repositories strictly; do not duplicate business logic in test helpers

## 🌍 Open Source & Contribution

- **License**: MIT ([LICENSE](.github/LICENSE))
- Required files: [`CONTRIBUTING.md`](CONTRIBUTING.md), [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md), [`SECURITY.md`](.github/SECURITY.md)
- Commit messages: [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `security:`)

## 🤖 AI Interaction Guidelines

1. Propose local/offline solutions first; flag privacy implications for any cloud suggestion
2. Respect Dart 3 conventions and feature-first Clean Architecture strictly
3. Generate production-ready code: error handling, loading states, edge cases covered
4. When modifying code, list impacted files and suggest corresponding tests to add/update
5. Never delete code without explicit justification and functional replacement
6. Apply YAGNI/KISS — keep implementations simple and direct
