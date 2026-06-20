---
name: codegen
description: 'Run build_runner after modifying freezed, drift, or json_serializable models. Use when: adding/editing @freezed classes, @JsonSerializable annotations, Drift table definitions, or any partible/generatable Dart code that requires code generation.'
argument-hint: '--delete-conflicting-outputs (default)'
---

# Codegen — build_runner automation

## When to Use
- Added or modified a `@freezed` class or sealed class
- Changed `@JsonSerializable` fields or annotations
- Modified Drift table definitions (`@Table`, `@DbField`)
- Created new `.dart` files with part directives expecting generated output
- User mentions "generate", "codegen", "build_runner", or reports missing `.g.dart` / `.freezed.dart` files

## Procedure

1. **Identify affected packages** — the command runs in the project root (`/home/pv/Mamadera/mamadera`) where `pubspec.yaml` lives.

2. **Run codegen (use Makefile target):**
   ```bash
   make codegen
   ```

3. **Validate output:**
   - Check for missing `.g.dart`, `.freezed.dart`, or drift generated files
   - Run `flutter analyze --fatal-infos --fatal-warnings` to catch unresolved imports
   - If errors reference "target of URI hasn't been generated", the build_runner run may have failed — re-run with verbose output:
     ```bash
     dart run build_runner build -v --delete-conflicting-outputs
     ```

## Notes
- Always use `--delete-conflicting-outputs` to avoid stale generated files causing conflicts
- After codegen, if models changed shape, check impacted tests in `test/features/<module>/domain/` and `test/data/` for breakages
