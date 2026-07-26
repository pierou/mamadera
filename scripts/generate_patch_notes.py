#!/usr/bin/env python3
"""Generate patch notes JSON from git Conventional Commits.

Parses git log between the last tag and HEAD (or a specified range), groups
commits by type, and outputs locale-specific JSON files.

Usage:
    python3 scripts/generate_patch_notes.py
    python3 scripts/generate_patch_notes.py --version=1.1.0
    python3 scripts/generate_patch_notes.py --lang=fr
    python3 scripts/generate_patch_notes.py --show-chore

Returns exit code 0 on success, 1 on error.
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Optional


class CommitType(Enum):
    """Conventional commit types mapped to patch notes categories."""
    FEAT = 'feat'
    FIX = 'fix'
    PERF = 'perf'
    SECURITY = 'security'
    CHORE = 'chore'
    DOCS = 'docs'
    STYLE = 'style'
    REFACTOR = 'refactor'
    TEST = 'test'
    BUILD = 'build'
    CI = 'ci'
    OTHER = 'other'


# Category translations for EN and FR
CATEGORIES = {
    'en': {
        'feat': 'New Features',
        'fix': 'Bug Fixes',
        'perf': 'Performance Improvements',
        'security': 'Security Fixes',
        'other': 'Other Changes',
    },
    'fr': {
        'feat': 'Nouvelles fonctionnalités',
        'fix': 'Corrections de bugs',
        'perf': 'Améliorations de performances',
        'security': 'Correctifs de sécurité',
        'other': 'Autres modifications',
    },
}

# Commit types to include by default (chore/docs/etc. are hidden unless --show-chore)
DEFAULT_COMMIT_TYPES = {CommitType.FEAT, CommitType.FIX, CommitType.PERF, CommitType.SECURITY}
ALL_COMMIT_TYPES = set(CommitType)


@dataclass
class Commit:
    """A parsed conventional commit."""
    type: CommitType
    scope: Optional[str]
    description: str
    hash: str


class PatchNotesGenerator:
    """Generate patch notes JSON from git Conventional Commits."""

    # Conventional commit regex: type(scope): description or type: description
    _COMMIT_RE = re.compile(
        r'^([a-zA-Z]+)(?:\(([^)]+)\))?!?:\s+(.+)$',
        re.MULTILINE,
    )

    def __init__(
        self,
        version: str,
        date: Optional[str] = None,
        lang: str = 'en',
        output_dir: Path = Path('assets/patch_notes'),
        show_chore: bool = False,
    ) -> None:
        self.version = version
        self.date = date or datetime.now(timezone.utc).strftime('%Y-%m-%d')
        self.lang = lang
        self.output_dir = output_dir
        self.show_chore = show_chore
        self.commits: list[Commit] = []

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def fetch_commits(self) -> None:
        """Fetch commits from git between last tag and HEAD."""
        result = subprocess.run(
            ['git', 'log', '--oneline', '--no-decorate'],
            capture_output=True,
            text=True,
            check=True,
        )
        lines = result.stdout.strip().split('\n')
        if not lines or lines == ['']:
            print('Error: No commits found.', file=sys.stderr)
            sys.exit(1)

        for line in lines:
            commit = self._parse_commit(line)
            if commit:
                self.commits.append(commit)

        if not self.commits:
            print('Error: No conventional commits found.', file=sys.stderr)
            sys.exit(1)

    def generate(self) -> dict:
        """Generate patch notes structure grouped by category."""
        categories = self._group_commits()
        title = self._get_title()

        items: list[str] = []
        for category_key in ['feat', 'fix', 'perf', 'security', 'other']:
            category_commits = categories.get(category_key)
            if not category_commits:
                continue

            category_name = CATEGORIES.get(self.lang, CATEGORIES['en']).get(category_key, category_key)
            items.append(f'### {category_name}')
            items.extend(
                f'- {self._format_commit_description(commit)}'
                for commit in category_commits
            )
            items.append('')  # blank line between categories

        return {
            self.version: {
                'releaseDate': self.date,
                'title': title,
                'items': items,
            },
        }

    def save(self, notes: dict) -> Path:
        """Save patch notes JSON to file."""
        lang = self.lang if self.lang in ('en', 'fr') else 'en'
        output_file = self.output_dir / f'{lang}.json'
        output_file.parent.mkdir(parents=True, exist_ok=True)
        output_file.write_text(json.dumps(notes, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        print(f'✓ Patch notes written to {output_file}')
        return output_file

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _parse_commit(self, line: str) -> Optional[Commit]:
        """Parse a git commit line into a Commit object."""
        # Extract hash and description from "hash description" format
        match = re.match(r'^([0-9a-f]+)\s+(.+)$', line)
        if not match:
            return None

        commit_hash = match.group(1)
        description = match.group(2)

        # Parse conventional commit format
        conv_match = self._COMMIT_RE.match(description)
        if not conv_match:
            return None

        commit_type_str = conv_match.group(1).lower()
        scope = conv_match.group(2)
        desc = conv_match.group(3).strip()

        # Map type to CommitType enum
        try:
            commit_type = CommitType(commit_type_str)
        except ValueError:
            commit_type = CommitType.OTHER

        # Filter by commit types
        if not self.show_chore and commit_type not in DEFAULT_COMMIT_TYPES:
            return None

        return Commit(
            type=commit_type,
            scope=scope,
            description=desc,
            hash=commit_hash,
        )

    def _group_commits(self) -> dict[str, list[Commit]]:
        """Group commits by type."""
        categories: dict[str, list[Commit]] = {}
        for commit in self.commits:
            type_key = commit.type.value
            if type_key not in categories:
                categories[type_key] = []
            categories[type_key].append(commit)
        return categories

    def _get_title(self) -> str:
        """Generate localized title."""
        if self.lang == 'fr':
            return f"Nouvelles Fonctionnalités de Mamadera {self.version}"
        return f"What's New in Mamadera {self.version}"

    def _format_commit_description(self, commit: Commit) -> str:
        """Format commit description for patch notes."""
        desc = commit.description
        # Capitalize first letter
        if desc:
            desc = desc[0].upper() + desc[1:]
        # Remove trailing period
        desc = desc.rstrip('.')
        return desc


def get_version_from_pubspec() -> str:
    """Extract version from pubspec.yaml."""
    pubspec = Path('pubspec.yaml')
    if not pubspec.exists():
        print('Error: pubspec.yaml not found.', file=sys.stderr)
        sys.exit(1)

    for line in pubspec.read_text().split('\n'):
        if line.startswith('version:'):
            version_str = line.split(':')[1].strip()
            # Version format is "1.0.0+1", we only want "1.0.0"
            return version_str.split('+')[0]

    print('Error: Could not find version in pubspec.yaml.', file=sys.stderr)
    sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Generate patch notes JSON from git Conventional Commits.',
    )
    parser.add_argument(
        '--version',
        type=str,
        default=None,
        help='Version string (default: from pubspec.yaml)',
    )
    parser.add_argument(
        '--date',
        type=str,
        default=None,
        help='Release date in YYYY-MM-DD format (default: today)',
    )
    parser.add_argument(
        '--lang',
        type=str,
        default='en',
        choices=['en', 'fr'],
        help='Locale for patch notes (default: en)',
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('assets/patch_notes'),
        help='Output directory for JSON files (default: assets/patch_notes)',
    )
    parser.add_argument(
        '--show-chore',
        action='store_true',
        default=False,
        help='Include chore/docs/style/refactor commits in output',
    )

    args = parser.parse_args()

    # Determine version
    version = args.version or get_version_from_pubspec()

    # Create generator and run
    generator = PatchNotesGenerator(
        version=version,
        date=args.date,
        lang=args.lang,
        output_dir=args.output_dir,
        show_chore=args.show_chore,
    )

    print(f'Generating patch notes for v{version} ({args.lang})...')
    generator.fetch_commits()
    print(f'  Found {len(generator.commits)} conventional commit{"s" if len(generator.commits) != 1 else ""}')

    notes = generator.generate()
    generator.save(notes)
    print('Done!')


if __name__ == '__main__':
    main()
