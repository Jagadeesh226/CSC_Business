# Frontend agent rules (Vite + React + TypeScript)

You own `frontend/` only. Read the root `AGENTS.md` first.

## Source of truth for the API
- Types and client come from `docs/contracts/openapi.json`.
- Generate with `bash scripts/gen_frontend_api.sh` (writes `frontend/src/api/schema.d.ts`).
- Never hand-write API types and never edit `schema.d.ts` by hand.
- If the API you need does not exist, build against the mock server
  (`bash scripts/mock_api.sh`, port 4010) and list the missing endpoint in your reply.
  Do not touch `backend/`.

## Rules
1. TypeScript strict. No `any` unless unavoidable and commented.
2. Server data via TanStack Query; forms via React Hook Form + Zod.
3. Hiding a button is not security. Assume the backend will return 403 and handle it
   with a clear message.
4. Never put secrets in the frontend. Only `VITE_*` public settings. Never read `.env.local`.
5. Never render raw HTML from user or OCR data. Mask Aadhaar/PAN/chassis/engine in lists.
6. Accessibility: status as text plus colour, keyboard navigation, readable contrast,
   large click targets, visible focus.
7. Every screen needs loading, empty and error states.

## Quality bar (the "wow" is speed and clarity for staff)
- New Job flow is keyboard-first: mobile number first, existing-customer match,
  progress for uploads and OCR, unsaved-changes warning.
- OCR review: document preview beside the fields, low-confidence fields highlighted.
- Ctrl+K command palette for customers, jobs, vehicles.
- Expiry dashboard with 0-7, 8-15, 16-30 day buckets and one-click WhatsApp link.
- Consistent design tokens (colours, spacing, type) defined once in one place.

## Done means
`scripts/check.sh frontend` passes (tsc, eslint, tests if present, build).
