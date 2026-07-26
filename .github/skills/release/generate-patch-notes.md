# Generate Patch Notes Skill

Generate patch notes from git Conventional Commits before each release.

## When to Run

- **Before each release** — after merging feature branches
- **After major changes** — when user-facing changes need to be documented
- **Automatically** — as part of release preparation workflow

## How to Run

### Basic Usage

```bash
# Generate for current version (extracted from pubspec.yaml)
make patch-notes

# Generate for specific version
make patch-notes VERSION=1.1.0

# Generate with different locale
make patch-notes LANG=fr

# Generate with specific date
make patch-notes DATE=2026-08-01

# Combine options
make patch-notes VERSION=1.1.0 LANG=fr DATE=2026-08-01
```

### Advanced Usage

```bash
# Include chore/docs commits (hidden by default)
python3 scripts/generate_patch_notes.py --show-chore

# Custom output directory
python3 scripts/generate_patch_notes.py --output-dir=docs/releases

# Both locales at once
make patch-notes LANG=en
make patch-notes LANG=fr
```

## How to Review

1. **Check generated JSON** — review `assets/patch_notes/en.json` and `assets/patch_notes/fr.json`
2. **Edit descriptions** — AI-generated from commit messages can be refined:
   - Make descriptions user-friendly (not technical)
   - Group related changes under categories
   - Add context where needed
3. **Verify formatting** — ensure proper JSON structure and escaping

## Commit Types Mapped to Categories

| Commit Type | English Category | French Category |
|-------------|-----------------|-----------------|
| `feat:` | New Features | Nouvelles fonctionnalités |
| `fix:` | Bug Fixes | Corrections de bugs |
| `perf:` | Performance Improvements | Améliorations de performances |
| `security:` | Security Fixes | Correctifs de sécurité |
| `chore:`, `docs:`, etc. | Other Changes (hidden) | Autres modifications (masqué) |

## How to Commit

1. Generate patch notes: `make patch-notes`
2. Review generated JSON files
3. Edit descriptions if needed (AI-generated from commit messages)
4. Commit both locale files:
   ```bash
   git add assets/patch_notes/en.json assets/patch_notes/fr.json
   git commit -m "chore: update patch notes for v1.1.0"
   ```

## JSON Structure

```json
{
  "1.1.0": {
    "releaseDate": "2026-08-01",
    "title": "What's New in Mamadera 1.1",
    "items": [
      "### New Features",
      "- Track baby's growth measurements",
      "- Export data to CSV format",
      "",
      "### Bug Fixes",
      "- Fix sleep duration calculation",
      ""
    ]
  }
}
```

## Troubleshooting

- **"No commits found"** — Make sure you're on the correct branch with commits
- **"No conventional commits found"** — Commits must follow Conventional Commits format (`feat:`, `fix:`, etc.)
- **"pubspec.yaml not found"** — Run from project root directory
