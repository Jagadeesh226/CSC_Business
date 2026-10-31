
#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAILED=()

run() {
  local label="$1"
  shift
  echo
  echo "=== $label ==="
  if "$@"; then
    echo "PASS: $label"
  else
    echo "FAIL: $label"
    FAILED+=("$label")
  fi
}

backend() {
  if [[ ! -d backend ]]; then
    echo "ERROR: backend/ directory missing."
    FAILED+=("backend directory")
    return
  fi

  if [[ ! -f backend/pyproject.toml || ! -f backend/uv.lock ]]; then
    echo "ERROR: backend/pyproject.toml or backend/uv.lock missing."
    FAILED+=("backend dependency files")
    return
  fi

  run "backend: dependency lock" \
    bash -c 'cd backend && uv lock --check'

  run "backend: Ruff lint" \
    bash -c 'cd backend && uv run ruff check app tests'

  run "backend: Ruff format" \
    bash -c 'cd backend && uv run ruff format --check app tests'

  run "backend: pytest" \
    bash -c 'cd backend && uv run pytest'

  contract
}

frontend() {
  if [[ ! -d frontend ]]; then
    echo "ERROR: frontend/ directory missing."
    FAILED+=("frontend directory")
    return
  fi

  if [[ ! -f frontend/package.json || ! -f frontend/package-lock.json ]]; then
    echo "ERROR: frontend package files missing."
    FAILED+=("frontend dependency files")
    return
  fi

  run "frontend: npm ci" \
    bash -c 'cd frontend && npm ci'

  run "frontend: TypeScript build" \
    bash -c 'cd frontend && npm run build'

  run "frontend: ESLint" \
    bash -c 'cd frontend && npm run lint'
}

contract() {
  if [[ ! -f scripts/export_openapi.py ]]; then
    echo "ERROR: scripts/export_openapi.py missing."
    FAILED+=("contract exporter missing")
    return
  fi

  if [[ ! -f docs/contracts/openapi.json ]]; then
    echo "ERROR: docs/contracts/openapi.json missing."
    FAILED+=("OpenAPI contract missing")
    return
  fi

  local tmp
  tmp="$(mktemp)"
  if (
    cd backend
    uv run python ../scripts/export_openapi.py --out "$tmp"
  ); then
    if diff -q "$tmp" docs/contracts/openapi.json >/dev/null; then
      echo "PASS: OpenAPI contract in sync"
    else
      echo "FAIL: OpenAPI contract differs from generated spec."
      FAILED+=("contract drift")
    fi
  else
    echo "FAIL: OpenAPI export failed."
    FAILED+=("contract export")
  fi
  rm -f "$tmp"
}

repo() {
  if command -v gitleaks >/dev/null 2>&1; then
    run "repo: Gitleaks" gitleaks detect --no-banner --redact
  else
    echo "SKIP: Gitleaks not installed."
  fi

  if command -v semgrep >/dev/null 2>&1; then
    run "repo: Semgrep" semgrep scan --config auto --error --quiet backend frontend/src
  else
    echo "SKIP: Semgrep not installed."
  fi
}

case "${1:-all}" in
  backend) backend ;;
  frontend) frontend ;;
  contract) contract ;;
  repo) repo ;;
  all) backend; frontend; repo ;;
  *)
    echo "Usage: $0 [backend|frontend|contract|repo|all]"
    exit 2
    ;;
esac

echo
if [[ "${#FAILED[@]}" -gt 0 ]]; then
  printf 'FAILED CHECKS:\n'
  printf ' - %s\n' "${FAILED[@]}"
  exit 1
fi

echo "All required checks passed."
