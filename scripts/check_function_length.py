#!/usr/bin/env python3
"""Checkpoint that no function/method body exceeds configured maximum line count.

Dart/SonarQube S1188 adherence checker for the mamadera project.

Usage:
    python3 scripts/check_function_length.py [--max=N] [--fail]

Returns exit code 0 if all functions <= N lines, 1 if violations found.
With --fail, exits 1 on violations (for CI pipeline).

Examples:
    python3 scripts/check_function_length.py                    # default 25
    python3 scripts/check_function_length.py --max=20           # 20-line rule
    flutter test --coverage && python3 scripts/check_function_length.py --max=20 --fail  # CI
"""

import re
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import Optional


@dataclass
class Violation:
    """A reported method/constructor exceeding the line limit."""
    file: str
    line: int  # 1-indexed
    name: str
    lines: int  # 0-indexed


class FunctionLengthChecker:
    """Analyze Dart source trees for method body length compliance."""

    _EXCLUDED_DIRS = {'generated', 'build', '.dart_tool', 'schema'}
    _EXCLUDED_FILES = ('.freezed.dart', '.g.dart', '.combined.dart', '.mocks.dart')

    # Dart keywords/constructors/state types that should never be treated as methods
    _METHOD_NAME_EXCLUSIONS = frozenset({
        'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
        'class', 'const', 'continue', 'default', 'deferred', 'do', 'dynamic',
        'else', 'enum', 'export', 'extends', 'extension', 'external', 'factory',
        'false', 'final', 'finally', 'for', 'Function', 'get', 'implements',
        'import', 'in', 'interface', 'is', 'late', 'library', 'mixin',
        'null', 'of', 'operator', 'part', 'required', 'rethrow', 'return',
        'sealed', 'static', 'super', 'switch', 'sync', 'this', 'throw',
        'true', 'typedef', 'var', 'void', 'while', 'with',
        # Dart async factory/state types
        'State', 'ConsumerState', 'ConsumerWidget', 'Consumer', 'StatefulWidget',
        'StatelessWidget', 'InheritedWidget', 'ChangeNotifier', 'Provider',
        'Widget', 'BuildContext',
    })

    # Control flow and expression keywords that should never be treated as methods
    _CONTROL_FLOW = frozenset({
        'if', 'for', 'while', 'switch', 'catch', 'do', 'case', 'default',
    })

    # Tokens that indicate non-method declarations (variable assignments, etc.)
    _NON_METHOD_PREFIXES = ('late ', 'final ', 'const ', 'var ')

    def __init__(self, max_lines: int = 25) -> None:
        self.max_lines = max_lines
        self.violations: list[Violation] = []

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def check_directory(self, root: Path) -> None:
        """Walk *root* and analyse every relevant .dart file."""
        files = sorted(
            f for f in root.rglob('*.dart')
            if not any(bad in f.name for bad in self._EXCLUDED_FILES)
            and not any(d in self._EXCLUDED_DIRS for d in f.parts)
        )
        print(f'Scanning {len(files)} Dart file{"s" if len(files) != 1 else ""} for functions > {self.max_lines} lines...')
        print()

        for fp in files:
            self._check_file(fp)

    def report(self, *, fail: bool = False) -> int:
        """Print a summary.  Returns 0 (pass) or 1 (fail)."""
        if not self.violations:
            print(f'All functions \u2264 {self.max_lines} lines. \u2714')
            return 0

        print(f'Found {len(self.violations)} function(s) exceeding {self.max_lines} lines:\n')
        for v in self.violations:
            print(f'  {v.file}:{v.line}: {v.name} ({v.lines} lines)')
        print()

        if fail:
            print('Tip: break long functions into smaller, focused helpers.')
            print(f'    Configure --max=N to adjust the limit.\n')

        return 1

    # ------------------------------------------------------------------
    # Per-file analysis
    # ------------------------------------------------------------------

    def _check_file(self, path: Path) -> None:
        content = self._read_file(path)
        if content is None:
            return

        all_lines = content.splitlines()
        i = 0
        while i < len(all_lines):
            match = self._try_find_method(all_lines, i)
            if match is None:
                i += 1
                continue

            effective_lines = match.end_line - match.start_line + 1
            if effective_lines > self.max_lines:
                self.violations.append(Violation(
                    file=str(path),
                    line=match.start_line + 1,  # 1-indexed for display
                    name=match.name,
                    lines=effective_lines,
                ))
            i = match.end_line + 1

    @staticmethod
    def _read_file(path: Path) -> Optional[str]:
        for enc in ('utf-8', 'latin-1', 'ascii'):
            try:
                return path.read_text(encoding=enc)
            except (UnicodeDecodeError, UnicodeError):
                continue
        return None

    # ------------------------------------------------------------------
    # Method detection logic
    # ------------------------------------------------------------------

    def _try_find_method(self, all_lines: list[str], start: int) -> 'MethodRegion | None':
        """Try to parse a Dart method declaration starting at *all_lines[start]*.

        Returns :class:`MethodRegion` if found, else ``None``.
        """
        line = all_lines[start]
        trimmed = line.strip()

        # Quick rejects
        if self._reject_early(trimmed):
            return None

        # Look ahead for the opening brace (may be on the same line or next few)
        brace_line = self._find_brace_line(all_lines, start, max_lookahead=3)
        if brace_line is None:
            return None

        # Check for arrow functions: `returnType name(params) => ...`
        # Arrow functions don't have their own block on this line
        decl_span = '\n'.join(all_lines[start : brace_line + 1])
        if '=>' in decl_span:
            return None

        # Extract name from the declaration span
        name = self._extract_method_name(all_lines[start : brace_line + 1])
        if name is None:
            return None

        # Find matching close brace
        close_line = self._find_matching_brace(all_lines, brace_line)
        if close_line is None:
            return None

        return MethodRegion(start, brace_line, close_line, name)

    @staticmethod
    def _reject_early(text: str) -> bool:
        """Does this line clearly NOT start a function declaration?"""
        t = text.strip()
        if not t:
            return True
        if t.startswith('//') or t.startswith('///') or t.startswith('/*') or t.startswith('#'):
            return True
        if t.startswith('@'):
            return True  # annotation only -- might be followed by method
        if t.startswith('import ') or t.startswith('export ') or t.startswith('part ') or t.startswith('library '):
            return True
        if any(t.startswith(p) for p in ('class ', 'abstract ', 'enum ', 'extension ', 'typedef ', 'mixin ', 'implements ')):
            return True
        if any(t.startswith(p) for p in ('if ', 'for ', 'while ', 'switch ', 'catch ', 'do ')):
            return True
        # Variable assignments: late/final/const/var followed by identifier and =
        if re.match(r'^(?:static\s+)?(?:[a-z\s]+\s+)?(?:final|late|const|var)\s+\S+\s*=', t):
            return True
        # Check for method-rejecting patterns in the line
        # If there's = before ( and no return type keyword, it's likely a variable assignment
        paren_match = re.search(r't.*(?::\s*\S+)?\s+\S+\s*\(', t)
        if paren_match and '=' in t.split('(')[0]:
            # There's an = before the (, likely a variable assignment
            return True
        return False

    @staticmethod
    def _find_brace_line(all_lines: list[str], start: int, *, max_lookahead: int = 3) -> int | None:
        """Return 0-indexed line number of the first { starting from *start*."""
        for j in range(start, min(start + max_lookahead + 1, len(all_lines))):
            stripped = all_lines[j].strip()
            if not stripped or stripped.startswith('//') or stripped.startswith('@') or stripped.startswith('/*'):
                continue
            if '{' in stripped:
                return j
        return None

    @staticmethod
    def _extract_method_name(first_lines: list[str]) -> str | None:
        """Extract method name from first line(s) of a method declaration."""
        first_line = first_lines[0].strip() if first_lines else ''
        decl_span = ' '.join(line.strip() for line in first_lines)

        # Find the position of ( arguments pair
        open_paren = decl_span.find('(')
        if open_paren < 0:
            return None

        # Text before the (
        before = decl_span[:open_paren].strip()

        # Split into tokens
        tokens = re.split(r'\s+', before)
        if not tokens:
            return None

        # The last token is usually the method/constructor name
        last_token = tokens[-1]

        # Empty token
        if not last_token:
            return None

        # Skip Dart keywords/state types (not methods)
        if last_token in FunctionLengthChecker._METHOD_NAME_EXCLUSIONS:
            return None

        # Skip generic-looking tokens (contains < or > - these are types, not method names)
        if any(ch in last_token for ch in ('<', '>')):
            return None

        # Skip control flow keywords
        if last_token in FunctionLengthChecker._CONTROL_FLOW:
            return None

        # Extract method name: must be lowercase (after optional _)
        effective_name = last_token.lstrip('_')
        if not effective_name or not effective_name[0].islower():
            return None

        # Must be identifier-like
        if not re.match(r'^[_a-zA-Z][_a-zA-Z0-9]*$', last_token):
            return None

        # Verify there's a return-type token before the method name
        # A valid method declaration has: [modifier] ReturnType name(params)
        # where ReturnType is a type-like token
        if len(tokens) < 2:
            return None

        # Get the token before the method name
        method_position = len(tokens) - 1  # last token
        before_method_tokens = tokens[:method_position]
        
        # Check if any token looks like a type/return type
        # Types can be: void, int, String, Future<T>, Stream<T>, List<T>, etc.
        # Or just lowercase keywords like late, static, final being modifiers (not types)
        has_type_before = False
        for t in before_method_tokens:
            # Skip Dart keywords that are modifiers (late, static, final, const, override)
            if t in ('late', 'static', 'final', 'const', 'override', 'required'):
                continue
            # Skip annotation decorators
            if t.startswith('@'):
                continue
            # If it looks like a type (uppercase start, or known type, or generic end), it's a return type
            if t[0].isupper() or t in FunctionLengthChecker._METHOD_NAME_EXCLUSIONS or any(ch in t for ch in ('<', '>')):
                has_type_before = True
                break

        if not has_type_before:
            return None

        return last_token

    @staticmethod
    def _find_matching_brace(all_lines: list[str], start: int) -> int | None:
        """Return 0-indexed line of the closing } that matches all_lines[start]'s {."""
        depth = 0
        found_open = False

        for j in range(start, len(all_lines)):
            line = all_lines[j]
            k = 0
            while k < len(line):
                ch = line[k]

                if ch == '{':
                    depth += 1
                    found_open = True
                elif ch == '}':
                    depth -= 1
                    if found_open and depth == 0:
                        return j

                # Skip string literals
                if ch in ('"', "'", '`'):
                    q = ch
                    m = k + 1
                    while m < len(line):
                        if line[m] == '\\':
                            m += 1
                        elif line[m] == q:
                            break
                        m += 1
                    k = m
                # Skip single-line comments
                elif ch == '/' and k + 1 < len(line) and line[k + 1] == '/':
                    break
                # Skip block comments
                elif ch == '/' and k + 1 < len(line) and line[k + 1] == '*':
                    m = k + 2
                    while m < len(line):
                        if m + 1 < len(line) and line[m] == '*' and line[m + 1] == '/':
                            m += 2
                            break
                        m += 1
                    k = m - 1

                k += 1

        return None


# ======================================================================
# Execution
# ======================================================================

@dataclass(frozen=True)
class MethodRegion:
    """Span of a method declaration in source lines (0-indexed, inclusive)."""
    start_line: int
    brace_line: int
    end_line: int
    name: str


def main() -> None:
    max_lines = 25
    fail = False

    for arg in sys.argv[1:]:
        if arg.startswith('--max='):
            try:
                max_lines = int(arg.split('=')[1])
            except ValueError:
                print(f'Invalid value for --max: {arg}', file=sys.stderr)
                sys.exit(1)
        elif arg == '--fail':
            fail = True
        else:
            print(f'Warning: Unknown argument: {arg}', file=sys.stderr)

    checker = FunctionLengthChecker(max_lines=max_lines)

    lib_dir = Path('lib')
    if not lib_dir.exists():
        print('lib/ directory not found.', file=sys.stderr)
        sys.exit(1)

    checker.check_directory(lib_dir)

    exit_code = checker.report(fail=fail)
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
