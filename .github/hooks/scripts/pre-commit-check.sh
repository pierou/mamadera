#!/usr/bin/env bash
# Pre-commit CI enforcement: runs full local CI (lint + tests + coverage ≥80%)
# before allowing git operations. Aligned with GitHub Actions pipeline.
# Exits 2 (blocking) if checks fail, 0 if they pass or are skipped.

set -euo pipefail

cd "$(dirname "$0")/../.." || exit 1

INPUT="${PRETOOLUSE_INPUT:-$1}"

GIT_ADD_REGEX='git add '
GIT_COMMIT_REGEX='git commit'
GIT_PUSH_REGEX='git push'

if [[ ! "$INPUT" =~ $GIT_ADD_REGEX ]] && \
   [[ ! "$INPUT" =~ $GIT_COMMIT_REGEX ]] && \
   [[ ! "$INPUT" =~ $GIT_PUSH_REGEX ]]; then
    exit 0
fi

echo "🔍 Running local CI (lint + tests + coverage) before git operation..." >&2

if make ci; then
    echo "✅ All CI checks passed!" >&2
    exit 0
else
    echo '{"systemMessage":"❌ Local CI failed. Fix issues before committing/pushing.", "stopReason": "CI check failed — run \`make ci\` to see full output (lint, tests, coverage ≥80%)."}' 
    exit 2
fi
