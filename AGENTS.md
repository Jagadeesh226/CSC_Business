
# CSC Business CRM: Rules for Every AI Agent

Read this file first, then read the AGENTS.md inside your assigned folder.

## Project

Internal CRM for a Common Service Centre: customers, jobs, documents, OCR, receipts, vehicle expiries, payments, and reporting.

Requirements: `docs/CSC_CRM_Development_Documentation_v1.0.docx`

Stack:
- Backend: FastAPI, Python 3.11, PostgreSQL, SQLAlchemy, Alembic
- Frontend: React, Vite, TypeScript
- Local infrastructure: Docker Compose, PostgreSQL, Redis
- Shared API contract: `docs/contracts/openapi.json`

## Ownership

| Path | Owner | Agent permissions |
|---|---|---|
| `backend/**` | Backend agent | Backend agent only |
| `frontend/**` | Frontend agent | Frontend agent only |
| `backend/**` and `frontend/**` | Integration agent | Integration agent only, for integration fixes |
| `docs/reviews/**` | Review agent | Review reports only |
| `docs/contracts/**` | Project owner | No agent may edit |
| `AGENTS.md` and nested `AGENTS.md` | Project owner | No agent may edit |
| `docs/SETUP-AI-WORKFLOW.md` | Project owner | No agent may edit |
| `README.md`, `compose.yaml`, `.gitignore` | Project owner | No agent may edit |
| `scripts/**`, `.github/**`, `infra/**` | Project owner | No agent may edit |
| `.env*` files | Nobody | Never read, print, copy, or edit |

Integration agents may edit both applications only to resolve API mismatches or failing integration tests. No new features.

## Hard Rules

1. Edit only within your assigned paths. If another path needs changes, report the request instead of editing it.
2. Treat `docs/contracts/openapi.json` as the approved API contract.
3. Never remove or rename an existing route, field, type, or status code without owner approval.
4. Adding a route or optional field requires contract review and regeneration.
5. Never read, print, log, or commit secrets or `.env*` files.
6. Use fake customer data in tests. Never request or paste real customer documents.
7. Run `bash scripts/check.sh backend` or `bash scripts/check.sh frontend` before reporting completion.
8. Keep changes small and commit on the assigned branch.
9. Do not add dependencies without explaining why.
10. Never weaken, skip, or delete tests to make checks pass.

Branch prefixes:
- `feat/backend-*`
- `feat/frontend-*`
- `feat/integration-*`
- `feat/review-*`
- `owner/*` for the project owner

## Security Acceptance Criteria

- Enforce authorization on every protected backend request, including record-level access.
- Mask Aadhaar, PAN, chassis, and engine numbers in list views and exports.
- Keep documents in private storage. Document URLs must not act as access credentials.
- Audit document access, customer/job changes, exports, and permission changes.
- OCR must not silently overwrite verified customer data.
- Payment and receipt creation must be idempotent.
- Escape spreadsheet cells beginning with `=`, `+`, `-`, or `@`.

## Completion Report

Report:
- Files changed
- Features implemented
- Tests and checks actually run
- Actual pass/fail results
- Dependencies added and why
- Contract changes requested
- Work that remains incomplete
