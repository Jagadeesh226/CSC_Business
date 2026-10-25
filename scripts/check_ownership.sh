#!/usr/bin/env bash
# Fails if the current branch changes files outside the folders its owner may edit.
# Usage:  scripts/check_ownership.sh [base-ref] [branch-name]
#   base-ref    default: origin/main (falls back to main)
#   branch-name default: current branch (CI passes the PR head branch)
set -euo pipefail

BASE="${1:-origin/main}"
BRANCH="${2:-$(git rev-parse --abbrev-ref HEAD)}"

git rev-parse --verify -q "$BASE" >/dev/null || BASE="main"
git rev-parse --verify -q "$BASE" >/dev/null || { echo "Base ref not found: $BASE" >&2; exit 2; }

# Which path patterns (space separated, shell globs) this branch may touch.
case "$BRANCH" in
  feat/backend-*|backend/*)          ALLOWED="backend/*" ;;
  feat/frontend-*|frontend/*)        ALLOWED="frontend/*" ;;
  feat/integration-*|integration/*)  ALLOWED="backend/* frontend/*" ;;
  feat/review-*|review/*)            ALLOWED="docs/reviews/*" ;;
  owner/*|main|master)               echo "Owner branch '$BRANCH': no restriction."; exit 0 ;;
  *) echo "Branch '$BRANCH' has no ownership rule. Use feat/backend-*, feat/frontend-*, feat/integration-*, feat/review-* or owner/*." >&2; exit 1 ;;
esac

# Never allowed on agent branches, whatever the prefix (checked first).
FORBIDDEN_RE='(^|/)\.env($|\.)|^compose\.yaml$|^infra/|^\.github/|^scripts/|^docs/contracts/|^AGENTS\.md$'

MB="$(git merge-base "$BASE" HEAD)"
CHANGED="$(git diff --name-only "$MB" HEAD)"

[ -z "$CHANGED" ] && { echo "No changes."; exit 0; }

bad=0
set -f   # no globbing: patterns like backend/* must stay patterns, not expand to file names
while IFS= read -r f; do
  if echo "$f" | grep -Eq "$FORBIDDEN_RE"; then
    echo "FORBIDDEN  $f  (owner-only file)"; bad=1; continue
  fi
  ok=0
  for pat in $ALLOWED; do
    # shellcheck disable=SC2254
    case "$f" in $pat) ok=1 ;; esac
  done
  if [ "$ok" -eq 0 ]; then echo "OUT OF BOUNDS  $f  (branch '$BRANCH' may edit: $ALLOWED)"; bad=1; fi
done <<< "$CHANGED"

if [ "$bad" -ne 0 ]; then
  echo; echo "Ownership check FAILED. Move those changes to the right owner or ask the project owner."; exit 1
fi
echo "Ownership check passed for '$BRANCH' ($(echo "$CHANGED" | wc -l | tr -d ' ') files)."
