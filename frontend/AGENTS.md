
# Frontend Agent Rules

You own `frontend/` only. Read the root `AGENTS.md` first.

## API Contract

Source of truth: `docs/contracts/openapi.json`.

Generate API types using:
`bash scripts/gen_frontend_api.sh`

Generated file:
`frontend/src/api/schema.d.ts`

Never hand-write API contract types or edit the generated file manually.

If an endpoint is missing:
1. Build against the mock API when its contract supports the required operation.
2. Report the missing endpoint and request a contract change.
3. Do not edit `backend/` or `docs/contracts/`.

## Existing Stack

- React + Vite + TypeScript
- TanStack Query for server state
- React Hook Form and Zod for forms and validation
- Centralized API access in `src/lib/api.ts`

Do not add dependencies without explaining why.

## Rules

1. Keep TypeScript strict. Avoid `any`; justify unavoidable uses.
2. Treat backend authorization as authoritative. Handle 401 and 403 responses with useful messages.
3. Never put secrets in frontend code or Vite environment variables.
4. Never read, print, or edit `.env.local`.
5. Never render untrusted user/OCR content as raw HTML.
6. Mask Aadhaar, PAN, chassis, and engine numbers in lists and exports.
7. Every screen needs loading, empty, error, and success states as appropriate.
8. Provide keyboard navigation, visible focus, readable contrast, and accessible status text.
9. Use the API contract for request/response types.

## UX Priorities

- New Job flow: mobile-number-first, existing-customer matching, upload/OCR progress, unsaved-change warning.
- OCR review: document preview beside fields; highlight low-confidence values.
- Ctrl+K command palette for customers, jobs, and vehicles.
- Expiry dashboard: 0–7, 8–15, and 16–30 day buckets, with a WhatsApp action.
- Define design tokens in one place.

## Done Means

Run `bash scripts/check.sh frontend` and report actual results. Do not claim completion if a check fails.
