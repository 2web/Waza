#!/usr/bin/env bash
# Russian fork: merge tw93/Waza upstream into the current branch, then rebuild
# generated files and re-run the checks. See FORK_RU.md.
#
# Usage: bash scripts/sync-upstream.sh [upstream-ref]   (default: upstream/main)
#        bash scripts/sync-upstream.sh --after-merge    (after resolving conflicts by hand)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PYTHONUTF8=1 PYTHONIOENCODING=utf-8

REF="${1:-upstream/main}"

if [ "$REF" = "--after-merge" ]; then
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    echo "Unresolved conflicts remain:" >&2
    git diff --name-only --diff-filter=U >&2
    exit 1
  fi
elif ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream https://github.com/tw93/Waza.git
fi

if [ "$REF" != "--after-merge" ] && [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean; commit or stash first." >&2
  exit 1
fi

[ "$REF" = "--after-merge" ] || git fetch upstream --tags

if [ "$REF" != "--after-merge" ] && ! git merge --no-ff --no-commit "$REF"; then
  # Generated files are always rebuilt from sources, so take upstream's copy
  # and let the generator below redo the fork's additions.
  for f in $(git diff --name-only --diff-filter=U); do
    case "$f" in
      plugins/waza/*|.claude-plugin/marketplace.json|.agents/plugins/marketplace.json)
        git checkout --theirs -- "$f" && git add -- "$f" ;;
    esac
  done
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    echo "Resolve these conflicts by hand (keep both sides of when_to_use lines):" >&2
    git diff --name-only --diff-filter=U >&2
    echo "Then rerun: bash scripts/sync-upstream.sh --after-merge" >&2
    exit 1
  fi
fi

python3 scripts/build_metadata.py
# Python on Windows writes CRLF; the repository uses LF.
git ls-files -m -o --exclude-standard -- plugins .claude-plugin .agents \
  | while read -r f; do sed -i 's/\r$//' "$f"; done
git add -A plugins .claude-plugin .agents

python3 scripts/build_metadata.py --check >/dev/null
python3 scripts/verify_skills.py --root . >/dev/null
python3 scripts/check_routing_drift.py --root . >/dev/null
bash tests/test_punctuation_ru.sh

echo "Merge staged and checks passed. Review with 'git diff --cached', then commit."
