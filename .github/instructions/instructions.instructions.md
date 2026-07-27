---
description: Always Load these instructions for the Mamadera project. They contain the project-specific coding conventions, architecture, and AI interaction rules.
---
# Mamadera — AI Agent Instructions

Privacy-first newborn tracking app. **Offline-only, zero telemetry.** iOS & Android targets.

## 🔒 Non-Negotiables
| Rule | Detail |
|------|--------|
| 🚫 No analytics/telemetry | Never add cloud crash reporting, analytics SDKs, or trackers |
| 🚫 No data leakage | Audit deps for privacy before adding |
| ✅ Local-only storage | Data stays on device. Export: encrypted JSON or CSV only |
| ✅ Encryption at rest | Sensitive fields (notes, weight, allergies) via `flutter_secure_storage` + AES-GCM |

## 🧱 Tech Stack
- **State:** `flutter_riverpod` — `StateNotifier` + `AsyncNotifier`. No mixin-based state mgmt.
- **Routing:** `go_router`
- **DB:** `drift` (SQLite), schema in `lib/data/local/schema.sql`
- **Models:** `freezed` + `json_annotation` + `build_runner` codegen → run `make codegen` after changes

## 🏗️ Architecture: Feature-First Clean Layers
```
lib/features/<module>/
├── domain/repositories/   # Abstract interface (pure Dart, no Flutter deps)
├── data/repositories/     # Concrete impl (injects AppDatabase + EncryptionService)
└── presentation/          # UI screens, widgets, Riverpod providers & notifiers
```
- **Domain:** pure logic. `abstract class` repository interfaces here.
- **Data:** implement repos. Encrypt before DB insert; decrypt on read.
- **Presentation:** depend on repo providers only — never directly on DB.

## 💻 Coding Conventions
- `final` / `const` everywhere possible. Widgets > ~25 lines → extract sub-widget.
- Prefer `sealed class` for states/events (exhaustive switching).
- Naming: `camelCase` vars/functions, `PascalCase` classes/widgets, `snake_case` files/dirs.
- Logging: `logger` package only — **never** `print()`.
- Riverpod tests: override providers with `ProviderContainer(overrides: [...])`.

## 🛠️ Build Commands (`Makefile`)
| Command | Description |
|---------|-------------|
| `make codegen` | Run build_runner (freezed/drift/json_serializable) |
| `make lint` | `flutter analyze --fatal-infos --fatal-warnings` |
| `make test` | All tests with coverage (`--coverage`) |
| `make ci` | Full pipeline: pub-get → lint → test → ≥80% coverage check |

## 🧪 Testing Strategy
- **domain/** unit tests (pure logic, no mocks) in `test/features/<module>/domain/`
- **data/** unit tests with mocked DB+encryption in `test/data/`
- **presentation/** widget tests with ProviderContainer overrides in `test/presentation/`

## 🤖 AI Interaction Rules
1. Propose local/offline solutions first; flag privacy implications for cloud features
2. Respect Dart 3 conventions and Clean Architecture strictly
3. Production-ready code: error handling, loading states, edge cases covered
4. List impacted files + suggest tests when modifying code
5. Never delete without justification and functional replacement
6. Apply YAGNI/KISS — simple and direct

---

## Skill Index (Read On-Demand)

Detailed conventions are split into topical skill files under `.github/skills/`. Load them only when relevant to the current task.

| Topic | File | When to Use |
|-------|------|-------------|
| **Code Generation** | [../skills/codegen/SKILL.md](../skills/codegen/SKILL.md) | Run `build_runner` after modifying `@freezed`, `@JsonSerializable`, or Drift models |
| **iOS HIG** | [../skills/ios-hig/SKILL.md](../skills/ios-hig/SKILL.md) | Designing iOS UIs, accessibility (VoiceOver, Dynamic Type), dark mode, touch targets, haptics, permissions |
| **State Management** | [../skills/flutter/state-management.md](../skills/flutter/state-management.md) | Building `StateNotifier`, `AsyncNotifier`, Riverpod patterns (project uses Riverpod) |
| **Routing & Navigation** | [../skills/flutter/routing-navigation.md](../skills/flutter/routing-navigation.md) | Setting up `go_router`, deep links, auth redirects |
| **Code Quality & Style** | [../skills/flutter/code-quality.md](../skills/flutter/code-quality.md) | Naming conventions, SOLID principles, logging, function limits |
| **Data Handling & Serialization** | [../skills/flutter/data-serialization.md](../skills/flutter/data-serialization.md) | JSON models (`json_serializable`), async/await patterns, null safety |
| **UI Design & Theming (Material 3)** | [../skills/flutter/ui-design-theming.md](../skills/flutter/ui-design-theming.md) | `ThemeData`, color schemes, typography, shadows, dark mode |
| **Layout Best Practices** | [../skills/flutter/layout-best-practices.md](../skills/flutter/layout-best-practices.md) | Expanded/Flexible/Wrap/ListView builder choices, const constructors |

> **Note:** Project-specific rules above take precedence over general Flutter skills. This project uses Riverpod, `logger` for logging, and Drift for persistence.
