#!/usr/bin/env bash
# Fake API generated from the contract, so the frontend can be built before the backend exists.
# Point the frontend at http://localhost:4010 (e.g. VITE_API_URL in frontend/.env.local).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/docs/contracts/openapi.json"
[ -f "$SPEC" ] || { echo "Missing $SPEC" >&2; exit 1; }
exec npx --yes @stoplight/prism-cli mock -d -p 4010 "$SPEC"
