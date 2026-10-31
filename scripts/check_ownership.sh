
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE="${1:-origin/main}"
BRANCH="${2:-$(git branch --show-current)}"

if [[ "$BRANCH" == "owner/"* || "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "Owner branch '$BRANCH': ownership restrictions not applied."
  exit 0
fi

case "$BRANCH" in
  feat/backend-*) ALLOWED=("backend/") ;;
  feat/frontend-*) ALLOWED=("frontend/") ;;
  feat/integration-*) ALLOWED=("backend/" "frontend/") ;;
  feat/review-*) ALLOWED=("docs/reviews/") ;;
  *)
    echo "ERROR: Branch '$BRANCH' has no ownership rule." >&2
    exit 1
    ;;
esac

git rev-parse --verify "$BASE" >/dev/null 2>&1 || {
  echo "ERROR: Base ref '$BASE' does not exist. Fetch the base branch first." >&2
  exit 2
}

MB="$(git merge-base "$BASE" HEAD)" || {
  echo "ERROR: Cannot determine merge base." >&2
  exit 2
}

bad=0

while IFS= read -r -d '' file; do
  case "$file" in
    .env|.env.*|*/.env|*/.env.*|\
    AGENTS.md|backend/AGENTS.md|frontend/AGENTS.md|\
    README.md|.gitignore|compose.yaml|\
    .github/*|.github/**/*|scripts/*|scripts/**/*|\
    docs/contracts/*|docs/contracts/**/*|\
    docs/SETUP-AI-WORKFLOW.md|docs/CSC_CRM_Development_Documentation_v1.0.docx|\
    infra/*|infra/**/*)
      echo "FORBIDDEN: $file"
      bad=1
      continue
      ;;
  esac

  allowed=0
  for prefix in "${ALLOWED[@]}"; do
    if [[ "$file" == "$prefix"* ]]; then
      allowed=1
      break
    fi
  done

  if [[ "$allowed" -eq 0 ]]; then
    echo "OUT OF BOUNDS: $file (branch '$BRANCH')"
    bad=1
  fi
done < <(git diff --name-only -z "$MB" HEAD)

if [[ "$bad" -ne 0 ]]; then
  echo "Ownership check FAILED."
  exit 1
fi

echo "Ownership check passed for '$BRANCH'."
