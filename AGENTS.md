# CSC Business CRM: rules for every AI agent

Read this file first. Then read the AGENTS.md inside the folder you were assigned.

## Project
Internal CRM for a Common Service Centre: customers, jobs, documents, OCR,
receipts, vehicle expiries. Full requirements: `docs/CSC_CRM_Development_Documentation_v1.0.docx`.

Stack: FastAPI + PostgreSQL (backend/), Vite + React + TypeScript (frontend/).

## Who owns what
| Path | Owner | Agents may edit? |
|---|---|---|
| `backend/` | Backend agent | Only the backend agent |
| `frontend/` | Frontend agent | Only the frontend agent |
| `docs/contracts/` | Project owner (human) | No. Propose changes in your report. |
| `docs/reviews/` | Review agent | Only the review agent (reports only) |
| `infra/`, `compose.yaml`, `scripts/`, `.github/`, root `AGENTS.md` | Project owner (human) | No |
| `.env`, `frontend/.env.local` | Nobody | Never read, print, copy or edit |

Integration agent: may edit `backend/` AND `frontend/`, but only to fix mismatches
between them and make tests pass. No new features.

## Hard rules
1. Edit only inside the folder you own. If a task needs a change elsewhere, stop and
   write the request at the end of your reply instead of making it.
2. The API contract is `docs/contracts/openapi.json`. Never change or delete an
   existing route, field, type or status code without the owner's approval. Adding a
   new route or optional field is fine; the owner will re-export the spec.
3. Never read, print, log or commit secrets or `.env*` files.
4. Use fake data only (fake names, fake mobile numbers, fake Aadhaar/PAN). Never ask
   for or paste real customer documents.
5. Run `scripts/check.sh <backend|frontend>` before saying a task is done. Paste real
   failures; do not hide, skip or weaken tests or checks to make them pass.
6. Keep changes small and on your own branch. Branch names:
   `feat/backend-*`, `feat/frontend-*`, `feat/integration-*`, `feat/review-*`.
7. Do not add dependencies without saying so and why.

## Security rules from the requirements document (all agents)
- Authorisation is enforced by the backend on every request. Hiding UI is not security.
- Mask Aadhaar, PAN, chassis and engine numbers in list views and exports.
- Document files stay in private storage; never use a document URL as an access credential.
- Audit log: document access, customer/job changes, exports, permission changes.
- OCR never silently overwrites verified customer data.
- Payments and receipts must be idempotent (retries must not create duplicates).
- Excel exports must escape cells beginning with `=`, `+`, `-`, `@`.
