# 🍼 Mamadera

**Privacy-first newborn tracking app.** Track your baby's feedings, sleep, diaper changes, and health routines — all stored locally on your device with end-to-end encryption. No cloud, no telemetry, no tracking.

[![CI](https://github.com/pvjio/mamadera/actions/workflows/ci.yml/badge.svg)](https://github.com/pvjio/mamadera/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](.github/SECURITY.md)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🍼 **Feedings** | Track breastfeeding and bottle feedings with optional duration |
| 😴 **Sleep** | Log naps and nighttime sleep sessions |
| 💩 **Diapers** | Record diaper changes at a glance |
| ❤️ **Health routines** | Eye cleaning, belly button care, vitamin D/K tracking and more |
| 📜 **History** | Browse all events chronologically with filtering support |
| 🔐 **Encryption** | All sensitive notes encrypted with AES-GCM before storage |

---

## 🏗️ Architecture

This project follows [Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) principles:

```
lib/
├── core/                      # Shared utilities (theme, encryption, entities)
│   ├── services/              # Encryption service & migration logic
│   ├── providers/             # Core Riverpod providers
│   └── theme.dart             # App-wide theming
├── data/                      # Data layer
│   ├── local/                 # Drift database (schema, DAOs)
│   │   ├── schema.sql         # DDL definitions
│   │   ├── app_db.dart        # Drift table & query classes
│   │   └── database.dart      # Database service singleton
├── features/                  # Feature modules (feature-first structure)
│   ├── home/                  # Tracking entry point
│   │   ├── domain/            # Pure business logic (entities, repositories interfaces)
│   │   ├── data/              # Repository implementations
│   │   └── presentation/      # Screens & state notifiers
│   ├── history/               # Event browsing feature
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   └── menu/                  # Settings / navigation hub
├── widgets/                   # Shared reusable UI components
└── main.dart                  # App entry point & initialization
```

### State Management

- **Riverpod** for all state management (`StateNotifier` and `AsyncNotifier`)
- No `Mixin`-based state management — explicit providers only

### Database

- **Drift** (SQLite) with versioned migrations
- Schema defined in a separate DDL file: [`lib/data/local/schema.sql`](lib/data/local/schema.sql)

---

## 🔒 Privacy & Security

| Principle | Implementation |
|-----------|----------------|
| **Local-first** | All data stored on-device via SQLite. No cloud sync by default. |
| **Encryption at rest** | Sensitive notes encrypted with AES-256-GCM before DB insertion |
| **Key storage** | Master key secured in platform-native keystore (iOS Keychain / Android Keystore) via `flutter_secure_storage` |
| **No telemetry** | Zero analytics, tracking, or external network calls by default |
| **Minimal permissions** | No camera, no location — only what's strictly necessary |
| **GDPR/CCPA/COPPA compliant** | Privacy policy included in-app. Open-source code audit welcome. |

### Encryption Flow

```
User input → AES-GCM encrypt (AES-256) → Store ciphertext in SQLite
                                       ↑
Master key stored securely ← flutter_secure_storage (Keychain / Keystore)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter `>=3.44.0` with Dart `>=3.4.0 <4.0.0`
- Android SDK or iOS tooling configured

### Installation

```bash
# Clone the repository
git clone https://github.com/pvjio/mamadera.git
cd mamadera

# Install dependencies
flutter pub get

# Generate Drift & Freezed code (if modified)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Makefile Commands

A `Makefile` is provided for local CI workflows:

| Command | Description |
|---------|-------------|
| `make ci` | Run full local CI (lint + tests) |
| `make lint` | Format check + static analysis |
| `make test` | Run unit & widget tests with coverage |
| `make check-coverage` | Enforce ≥ 80% line coverage threshold |
| `make build-android` | Build release APK |
| `make clean` | Clean all generated artifacts |

---

## 🧪 Testing

Tests are organized following the architecture rules:

```
test/
├── core/services/             # Encryption service unit tests
├── domain/entities/           # Entity model tests
├── data/repositories/         # Repository implementation tests (with mocks)
├── presentation/providers/    # Notifier & provider tests
└── widgets/                   # Widget/UI component tests
```

Run the test suite:

```bash
flutter test --coverage
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` / `riverpod` | State management |
| `drift` + `sqflite_common_ffi` | Local SQLite database |
| `encrypt` | AES-GCM encryption logic |
| `flutter_secure_storage` | Platform-native key storage |
| `go_router` | Declarative navigation |
| `freezed_annotation` / `json_annotation` | Code generation & serialization |
| `logger` | Structured logging |

---

## 🤝 Contributing

Contributions are welcome! Please read the following before submitting a PR:

- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Contributing Guidelines](.github/CONTRIBUTING.md)
- [Security Policy](.github/SECURITY.md)
- [Privacy Policy](.github/PRIVACY.md)

### Development Workflow

1. Create a feature branch from `develop`
2. Follow the clean architecture structure (`features/<module>/`)
3. Write tests for domain logic and data layer
4. Run `make ci` before pushing
5. Open a PR targeting `develop`

---

## 📄 License

This project is licensed under the MIT License — see [SECURITY.md](.github/SECURITY.md) for details.

---

### 🤖 AI-Assisted Development

Ce projet a été généré à l'aide d'une instance locale de **Qwen 3.6 Coder 27B**, sous la supervision de parents responsables. Aucun modèle cloud n'a été utilisé — tout est resté sur machine, dans le respect des principes de confidentialité défendus par cette application.

---

> Made with ❤️ for parents who value privacy as much as convenience.
