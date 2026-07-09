# Flutter Code Quality & Style Rules

## General Principles
* **SOLID:** Apply SOLID principles throughout the codebase.
* **Concise and Declarative:** Write concise, modern, technical Dart code. Prefer functional and declarative patterns.
* **Composition over Inheritance:** Favor composition for building complex widgets and logic.
* **Immutability:** Prefer immutable data structures. Widgets (especially `StatelessWidget`) should be immutable.

## Naming Conventions
* Avoid abbreviations in names.
* Use `PascalCase` for classes, `camelCase` for members/functions, `snake_case` for files/dirs.

## Code Structure
* Functions should be short (<20 lines) and single-purpose.
* Anticipate and handle potential errors — don't let code fail silently.
* **Logging:** Use `dart:developer` `log()` instead of `print()`.
