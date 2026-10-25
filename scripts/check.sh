#!/usr/bin/env bash
# One command every agent runs before saying "done".
# Usage: scripts/check.sh [backend|frontend|repo|contract|all]   (default: all)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FAILED=()

run() {  # run <label> <command...>
  local label="$1"; shift
  echo; echo "=== $label ==="
  if "$@"; then echo "PASS  $label"; else echo "FAIL  $label"; FAILED+=("$label"); fi
}
optional() {  # optional <tool> <label> <command...>  (skipped, with a note, if tool missing)
  local tool="$1" label="$2"; shift 2
  if command -v "$tool" >/dev/null 2>&1; then run "$label" "$@"
  else echo; echo "--- SKIP  $label  ('$tool' not installed)"; fi
}

pytest_cmd() {  # "no tests collected" (exit 5) is a warning, not a failure
  pytest -q; local rc=$?
  if [ "$rc" -eq 5 ]; then echo "WARN  no tests collected yet (write some!)"; return 0; fi
  return "$rc"
}

backend() {
  [ -d backend ] || { echo "no backend/ folder"; return; }
  [ -d backend/.venv ] && export PATH="$ROOT/backend/.venv/bin:$PATH"
  pushd backend >/dev/null
  optional ruff      "backend: ruff lint"   ruff check .
  optional ruff      "backend: ruff format" ruff format --check .
  optional mypy      "backend: mypy"        mypy app
  optional pytest    "backend: pytest"      pytest_cmd
  optional bandit    "backend: bandit"      bandit -q -r app
  optional pip-audit "backend: pip-audit"   pip-audit
  popd >/dev/null
  contract
}

contract() {  # exported spec must match the committed one
  [ -f scripts/export_openapi.py ] || return 0
  [ -d backend/.venv ] && export PATH="$ROOT/backend/.venv/bin:$PATH"
  local tmp; tmp="$(mktemp)"
  echo; echo "=== contract: openapi.json in sync with code ==="
  if python scripts/export_openapi.py --out "$tmp" >/dev/null 2>&1; then
    if [ -f docs/contracts/openapi.json ] && diff -q "$tmp" docs/contracts/openapi.json >/dev/null; then
      echo "PASS  contract in sync"
    else
      echo "FAIL  contract differs from docs/contracts/openapi.json (owner must review and re-export)"
      FAILED+=("contract drift")
    fi
  else
    echo "FAIL  could not export the spec (does the app import? are env vars/DB needed at import?)"
    FAILED+=("contract export")
  fi
  rm -f "$tmp"
}

frontend() {
  [ -d frontend ] || { echo "no frontend/ folder"; return; }
  if [ ! -d frontend/node_modules ]; then
    echo "FAIL  frontend: node_modules missing (run 'npm ci' in frontend/)"; FAILED+=("frontend deps"); return
  fi
  pushd frontend >/dev/null
  run "frontend: typecheck" npx tsc -b
  run "frontend: eslint"    npx eslint .
  if grep -q '"test"' package.json; then run "frontend: tests" npm test --silent -- --run; fi
  run "frontend: build"     npm run build --silent
  popd >/dev/null
}

repo() {
  optional gitleaks "repo: gitleaks (secrets)" gitleaks detect --no-banner --redact
  optional semgrep  "repo: semgrep"            semgrep scan --config auto --error --quiet backend frontend/src
}

case "${1:-all}" in
  backend)  backend ;;
  frontend) frontend ;;
  repo)     repo ;;
  contract) contract ;;
  all)      backend; frontend; repo ;;
  *) echo "usage: $0 [backend|frontend|repo|contract|all]"; exit 2 ;;
esac

echo
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "CHECKS FAILED:"; printf '  - %s\n' "${FAILED[@]}"; exit 1
fi
echo "All checks passed (skipped tools are listed above)."
