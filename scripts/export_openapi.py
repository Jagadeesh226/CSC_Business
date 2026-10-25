#!/usr/bin/env python3
"""Export the FastAPI OpenAPI spec to docs/contracts/openapi.json.

Run from anywhere:  python scripts/export_openapi.py
Optional:           python scripts/export_openapi.py --out some/other/file.json

Importing the app must not need a live database. If your settings require env vars at
import time, put safe dummy values in backend/.env.example and export them first.
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / "backend"
DEFAULT_OUT = ROOT / "docs" / "contracts" / "openapi.json"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    sys.path.insert(0, str(BACKEND))
    try:
        from app.main import app  # type: ignore[import-not-found]
    except Exception as exc:  # noqa: BLE001
        print(f"Could not import app.main: {exc!r}", file=sys.stderr)
        return 1

    spec = app.openapi()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    # sort_keys + indent => stable output, readable diffs
    args.out.write_text(json.dumps(spec, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {args.out} ({len(spec.get('paths', {}))} paths)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
