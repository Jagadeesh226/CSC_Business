#!/usr/bin/env bash
# Create one git worktree (separate folder + branch) per agent, next to this repo.
# Each folder is opened in its own editor window, so agents cannot overwrite each other.
# Usage: scripts/worktrees.sh setup | list | remove
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(dirname "$ROOT")"
NAME="$(basename "$ROOT")"
BASE="${BASE_BRANCH:-main}"

# folder-suffix : branch
TREES=(
  "backend:feat/backend-main"
  "frontend:feat/frontend-main"
  "integration:feat/integration-main"
  "review:feat/review-main"
)

case "${1:-}" in
  setup)
    for t in "${TREES[@]}"; do
      suffix="${t%%:*}"; branch="${t#*:}"; dir="$PARENT/$NAME-$suffix"
      if [ -d "$dir" ]; then echo "exists: $dir"; continue; fi
      git -C "$ROOT" worktree add -b "$branch" "$dir" "$BASE" 2>/dev/null \
        || git -C "$ROOT" worktree add "$dir" "$branch"
      echo "created: $dir  ->  $branch"
    done
    echo
    echo "Next: in $NAME-backend run:  cd backend && python -m venv .venv && .venv/bin/pip install -r requirements.txt"
    echo "      in $NAME-frontend run: cd frontend && npm ci"
    echo "      (node_modules and .venv are NOT shared between worktrees; .env files are not copied either)"
    ;;
  list)   git -C "$ROOT" worktree list ;;
  remove)
    for t in "${TREES[@]}"; do
      suffix="${t%%:*}"; dir="$PARENT/$NAME-$suffix"
      [ -d "$dir" ] && git -C "$ROOT" worktree remove "$dir" && echo "removed: $dir"
    done ;;
  *) echo "usage: $0 setup|list|remove"; exit 2 ;;
esac
