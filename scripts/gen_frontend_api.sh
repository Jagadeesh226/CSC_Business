#!/usr/bin/env bash
# Generate TypeScript API types for the frontend from the committed contract.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/docs/contracts/openapi.json"
OUT="$ROOT/frontend/src/api/schema.d.ts"

[ -f "$SPEC" ] || { echo "Missing $SPEC. Ask the owner to run: python scripts/export_openapi.py" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
cd "$ROOT/frontend"
npx --yes openapi-typescript "$SPEC" -o "$OUT"
echo "Generated $OUT"
