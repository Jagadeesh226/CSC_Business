# Backend agent rules (FastAPI)

You own `backend/` only. Read the root `AGENTS.md` first.

## Layout (keep it)
```
backend/app/
  api/           routers only: parse request, call a service, return a schema. No business logic.
  core/          config, security, auth dependencies, logging
  db/            session, base, migrations setup
  models/        SQLAlchemy models
  schemas/       Pydantic request/response models (these generate the OpenAPI contract)
  repositories/  database access only, no business rules
  services/      business rules and authorisation checks live here
  integration/   external adapters (OCR provider, storage). Keep behind an interface.
  workers/       background jobs (OCR, daily expiry check, exports)
  main.py        app creation and router registration
```

## Rules
1. Flow is always `api -> services -> repositories -> models`. Routers never touch the
   database directly.
2. Every route must declare `response_model`, proper status codes, and an auth
   dependency. Permission checks (role and record-level) go in `services`.
3. Schemas are the contract. When you add or change a schema or route, run
   `python scripts/export_openapi.py` and tell the owner the spec changed.
   Do not change existing fields; add new optional ones instead.
4. Error shape is consistent JSON. Never return stack traces, SQL, storage keys or
   secrets. Use 400/401/403/404/409/500 as defined in the requirements document.
5. Job IDs, customer codes and receipt numbers are generated server-side. Use
   database UUIDs internally.
6. Payment and receipt creation must be idempotent (idempotency key or unique constraint).
7. Write a pytest for each service function you add, including a permission-denied case.
8. Migrations: one Alembic migration per schema change, never edit an old one.

## Done means
`scripts/check.sh backend` passes (ruff, mypy, pytest, bandit, pip-audit, spec in sync).
