
# Backend Agent Rules

You own `backend/` only. Read the root `AGENTS.md` first.

## Existing Layout

Preserve the current structure:

- `app/main.py`: FastAPI app creation and router registration
- `app/core/`: configuration, security, authentication dependencies, logging
- `app/db/`: SQLAlchemy base, models, sessions
- `app/api/v1/`: API routers and endpoints
- `app/schemas/`: Pydantic request/response models
- `app/repositories/`: database access
- `app/services/`: business logic and authorization
- `app/services/integration/`: external service adapters
- `app/workers/`: background jobs as needed
- `migrations/`: Alembic migrations
- `tests/`: automated backend tests

Create missing directories only when needed. Do not reorganize existing code without the owner's approval.

## Architecture

1. Request flow: API router -> service -> repository -> SQLAlchemy model.
2. Routers parse requests, invoke services, and return response schemas.
3. Business rules and record-level authorization belong in services.
4. Repositories perform persistence and query operations, not business decisions.
5. Use Pydantic schemas for request and response validation.
6. Protected routes must declare authentication and appropriate authorization dependencies.
7. Use consistent HTTP status codes and safe JSON error responses.
8. Never expose stack traces, SQL statements, storage keys, or secrets in API responses.

## Database

- Use SQLAlchemy and Alembic, not Prisma.
- Use UUIDs internally where appropriate.
- Generate customer codes, job IDs where applicable, and receipt numbers server-side.
- Create one new Alembic migration for each schema change.
- Never edit an existing migration that may have been applied.
- Payment and receipt creation must have database-enforced idempotency.

## API Contract

The approved contract is `docs/contracts/openapi.json`.

When changing routes or schemas:
1. Explain the proposed contract change.
2. Do not edit `docs/contracts/`.
3. Run the OpenAPI export command when the app is importable.
4. Report the resulting spec differences and ask the owner to approve and commit them.

Command:
`python scripts/export_openapi.py`

## Tests and Security

- Write tests for each new service function.
- Include permission-denied tests for protected operations.
- Test validation errors, not-found cases, conflicts, and duplicate requests where relevant.
- Keep document access private and audited.
- Never allow OCR to overwrite verified fields without an explicit review workflow.
- Do not log secrets or sensitive identity/document contents.

## Done Means

Run `bash scripts/check.sh backend` and report the actual result. Do not claim checks passed if they were skipped or failed.
