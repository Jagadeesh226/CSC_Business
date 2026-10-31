# Running Four AI Agents in Parallel on the CSC CRM

Backend, frontend, integration, and review agents each work in their own folder, on their own branch, in their own editor window.

They coordinate through two things you control:

1. The API contract: `docs/contracts/openapi.json`
2. Your merges into `main`

The project uses the **existing repository structure**. Do not move the backend into a new `apps/api` directory or replace the current SQLAlchemy/Alembic setup with another framework.

---

## 1. What Goes Where

| File | Place in repo | Purpose |
|---|---|---|
| `AGENTS.md` | Repo root | Rules every agent reads first |
| `backend/AGENTS.md` | `backend/` | Backend agent rules and architecture |
| `frontend/AGENTS.md` | `frontend/` | Frontend agent rules |
| `docs/contracts/README.md` | `docs/contracts/` | API contract instructions |
| `docs/contracts/openapi.json` | `docs/contracts/` | Generated OpenAPI contract |
| `docs/contracts/permissions.md` | `docs/contracts/` | Role and permission matrix |
| `docs/reviews/README.md` | `docs/reviews/` | Where the review agent writes findings |
| `docs/SETUP-AI-WORKFLOW.md` | `docs/` | This file |
| `scripts/check.sh` | `scripts/` | Validation command for agents |
| `scripts/check_ownership.sh` | `scripts/` | Checks agent changes against folder ownership |
| `scripts/export_openapi.py` | `scripts/` | FastAPI app → OpenAPI contract |
| `scripts/gen_frontend_api.sh` | `scripts/` | OpenAPI contract → TypeScript API types |
| `scripts/mock_api.sh` | `scripts/` | Mock API server on port 4010 |
| `scripts/worktrees.sh` | `scripts/` | Creates a worktree and branch per agent |
| `.github/workflows/ownership.yml` | `.github/workflows/` | Runs ownership checks on pull requests |
| `.github/workflows/ci.yml` | `.github/workflows/` | Runs backend and frontend checks |
| `.github/CODEOWNERS` | `.github/` | Assigns code owners |

If files already exist at these paths, especially under `.github/`, review and merge the changes manually. Do not overwrite working configuration without checking it.

### Existing backend structure

Keep the backend structure already present in the repository, including:

```text
backend/
├── app/
│   ├── db/
│   │   ├── base.py
│   │   ├── models.py
│   │   └── session.py
│   ├── services/
│   │   └── integration/
│   └── main.py
├── migrations/
├── pyproject.toml
└── uv.lock
```

New modules should follow the current structure and the rules in `backend/AGENTS.md`. Do not move `app/db/models.py` into a new `app/models/` directory or move `app/services/integration/` elsewhere.

---

## 2. One-Time Setup

Perform this setup on `main`, or on an `owner/setup` branch that will be merged into `main`.

Run commands from the repository root.

```bash
# Move the requirements document only if it is not already in docs/
mv CSC_CRM_Development_Documentation_v1.0.docx docs/

# Make scripts executable
chmod +x scripts/*.sh scripts/*.py

# Install backend dependencies from the committed lock file
cd backend
uv sync --locked
cd ..

# Install frontend dependencies
cd frontend
npm ci
npm install -D openapi-typescript
cd ..

# Optional security tools
brew install gitleaks
```

If `CSC_CRM_Development_Documentation_v1.0.docx` is already in `docs/`, do not run the `mv` command again.

### Environment files

Create `backend/.env.example` with safe dummy values. Never use real credentials in this file.

For example:

```dotenv
DATABASE_URL=postgresql+psycopg://csc_app:fake_password@localhost:5433/csc_crm
SECRET_KEY=replace_with_a_fake_development_secret
```

Create your actual `backend/.env` locally. It must remain ignored by Git.

The frontend should use `VITE_API_BASE_URL` consistently. For example, create `frontend/.env.local` with:

```dotenv
VITE_API_BASE_URL=http://localhost:4010
```

This points the frontend to the mock API. When using the real FastAPI server, use the actual backend URL, such as:

```dotenv
VITE_API_BASE_URL=http://127.0.0.1:8000
```

Do not commit `.env`, `.env.local`, credentials, API keys, or real customer data.

### Git ignore requirements

Verify that `.gitignore` covers at least:

```gitignore
.env
.env.*
!.env.example
!.env.*.example

backend/.env
frontend/.env.local

.venv/
venv/
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage

node_modules/
dist/
.vite/
*.tsbuildinfo

.DS_Store
```

### Commit the setup

```bash
git checkout -b owner/setup
git add -A
git commit -m "Add AI workflow setup"

git checkout main
git merge owner/setup
```

Do not force-push to `main`.

---

## 3. Phase 0: Lock the API Contract

Complete this phase **before starting parallel implementation**.

The API contract is the shared interface between the backend and frontend agents.

1. Work with one backend agent only.
2. Create the Pydantic schemas and FastAPI route stubs for the first development slice:
   - Authentication
   - Customers
   - Services
   - Jobs
3. Follow the requirements document, especially section 10.
4. Export the OpenAPI contract:

   ```bash
   python scripts/export_openapi.py
   ```

5. Review the generated contract:

   ```bash
   git diff docs/contracts/openapi.json
   ```

6. Create `docs/contracts/permissions.md` using the role matrix from section 2 of the requirements document.
7. Review the API paths, request schemas, response schemas, status codes, and authorization requirements.
8. Commit the approved contract and route stubs to `main` through an `owner/*` branch.

**From this point onward, agents must not edit `docs/contracts/openapi.json` directly.**

If an agent needs a contract change, it must describe the requested change. You decide whether to approve it, update the backend schema or route, re-export the contract, and commit the change.

---

## 4. Start the Parallel Agents

Once the setup files and approved API contract are committed to `main`, create the worktrees.

```bash
bash scripts/worktrees.sh setup
```

This creates sibling directories next to your repository:

```text
<repo>-backend/
<repo>-frontend/
<repo>-integration/
<repo>-review/
```

Each worktree has its own branch:

| Worktree | Branch |
|---|---|
| Backend | `feat/backend-main` |
| Frontend | `feat/frontend-main` |
| Integration | `feat/integration-main` |
| Review | `feat/review-main` |

### Install dependencies in each worktree

Dependencies are not shared between worktrees. Run the setup commands printed by `scripts/worktrees.sh`.

Backend worktree:

```bash
cd ../<repo>-backend/backend
uv sync --locked
```

Frontend worktree:

```bash
cd ../<repo>-frontend/frontend
npm ci
```

Integration worktree:

```bash
cd ../<repo>-integration/backend
uv sync --locked

cd ../<repo>-integration/frontend
npm ci
```

Review worktree:

```bash
cd ../<repo>-review
```

The review agent generally does not need to install backend or frontend dependencies unless it is asked to run the test suites.

Each worktree needs its own local environment files. Copy only safe example files:

```bash
cp backend/.env.example backend/.env
```

For frontend development, create `frontend/.env.local` with the appropriate `VITE_API_BASE_URL`.

Do not copy real secrets into agent worktrees or expose them to hosted AI models.

Open each worktree in its own editor window. Never open the same worktree in two agent windows that may edit it simultaneously.

### Model selection

Model availability and free quotas change. Check the model picker before assigning agents.

| Agent | Suggested model | Fallback |
|---|---|---|
| Backend | Claude Opus in Antigravity | GLM, Kimi, or DeepSeek via Kilo |
| Frontend | Gemini Flash in Antigravity | Qwen Coder or DeepSeek via Kilo |
| Integration | Claude Sonnet in Antigravity | Same as backend |
| Review | GPT-OSS-120B or a different model family | DeepSeek or GLM via Kilo |

These are suggestions, not fixed requirements. Confirm current model availability in your editor.

If an agent does not automatically read `AGENTS.md`, paste the applicable instructions into its rules or custom-instructions field.

---

## 5. First Prompt for Each Agent

### Backend agent

> Read `AGENTS.md` and `backend/AGENTS.md`.
>
> Implement `<module>` following `docs/CSC_CRM_Development_Documentation_v1.0.docx` and the approved `docs/contracts/openapi.json`.
>
> Preserve the existing backend structure, including `app/db/models.py` and `app/services/integration/`. Follow the project's established layering and conventions. Put authorization checks in the appropriate service layer. Add pytest tests for the implemented services, including permission-denied cases.
>
> Do not modify the API contract directly. If a contract change is needed, report the proposed change and wait for approval.
>
> Run `bash scripts/check.sh backend` and report the results. Do not touch files outside your assigned backend ownership.

### Frontend agent

> Read `AGENTS.md` and `frontend/AGENTS.md`.
>
> Generate API types using `bash scripts/gen_frontend_api.sh`. Use the mock API from `bash scripts/mock_api.sh` while developing against the approved contract.
>
> Build `<screen>` according to the requirements document, including loading, empty, error, and success states.
>
> Use `VITE_API_BASE_URL` for the API base URL. Do not hand-write API types or edit the generated API schema file.
>
> Run `bash scripts/check.sh frontend` and report the results. Do not modify `backend/`.

### Integration agent

Start the integration agent **only after the backend and frontend changes have been merged into `main`**.

> Read `AGENTS.md`.
>
> Run the real backend and frontend together. Fix only integration mismatches, incorrect API wiring, and failing tests. Do not add new features or change the approved API contract without approval.
>
> Run `bash scripts/check.sh all` and report the results. Keep changes limited to the backend and frontend areas permitted for the integration branch.

### Review agent

> Read `AGENTS.md` and `docs/reviews/README.md`.
>
> Review `<branch/module>` against the requirements document, especially sections 2, 11, and 13.
>
> Focus on authorization gaps, missing audit logging, data exposure, injection risks, file-upload handling, idempotency, and API contract drift.
>
> Do not edit application code. Write findings to `docs/reviews/<date>-<topic>.md`. Each finding must include the affected file and line, how to trigger the issue, its impact, and a suggested fix.
>
> Report findings only. Do not implement fixes.

---

## 6. Daily Development Loop

1. Each agent works on its assigned branch and files.
2. The agent runs the relevant checks:

   ```bash
   bash scripts/check.sh backend
   ```

   or:

   ```bash
   bash scripts/check.sh frontend
   ```

3. The agent commits its changes on its own branch.
4. Before opening a pull request, run:

   ```bash
   bash scripts/check_ownership.sh
   ```

5. Review the pull request and merge only after the required checks pass.

### Recommended merge order

1. Merge backend.
2. Re-export and review the OpenAPI contract.
3. Regenerate frontend API types.
4. Merge frontend.
5. Run the integration agent.
6. Merge integration fixes.
7. Run the review agent against the merged code.
8. Address review findings through the appropriate owner branch.

After merging backend, update the frontend worktree:

```bash
cd ../<repo>-frontend
git fetch origin
git merge origin/main
bash scripts/gen_frontend_api.sh
```

TypeScript errors can now expose mismatches between the frontend and the updated API contract.

If an agent needs a contract change, it must report the request. You approve the change, update the backend implementation or schema, re-export the contract, and commit it.

---

## 7. GitHub Settings

In GitHub:

1. Open **Settings → Branches**.
2. Add a branch protection rule for `main`.
3. Require pull requests before merging.
4. Require the `ownership-check` status check.
5. Require review from Code Owners.
6. Require the CI checks to pass.

`CODEOWNERS` alone does not prevent agents from editing files. Branch protection and the ownership-check workflow enforce the review process.

Replace the username placeholder in `.github/CODEOWNERS` with your actual GitHub username.

---

## 8. Troubleshooting

### `export_openapi.py` fails

The FastAPI app may require environment variables or a database connection during import.

- Ensure the app can be imported without connecting to a live database.
- Move database-dependent work to application startup or request execution.
- Use safe dummy environment values for contract generation.
- Do not put real credentials in the contract-generation environment.

### Branch already checked out

A Git branch can be checked out in only one worktree.

```bash
git worktree list
```

Use the existing worktree for that branch or create a new branch with a different name.

### Database port conflict

If PostgreSQL is already using port `5432`, use the port configured in `compose.yaml`—currently `5433` on the host—or stop the conflicting service.

Run one development PostgreSQL instance and point the backend worktrees to it. Only the backend worktree responsible for the current schema change should run migrations.

Do not delete Docker volumes with `docker compose down -v` unless you intentionally want to delete the persisted database data.

### Agent edited files outside its ownership

Inspect the changes:

```bash
git diff --stat main
git diff --name-only main
```

Revert unauthorized changes and tighten the agent prompt. Run the ownership check before opening a pull request.

### Contract drift

If frontend types or API behavior no longer match the contract:

1. Stop the affected agent.
2. Identify whether the backend or contract is incorrect.
3. Request approval for any contract change.
4. Re-export the OpenAPI document.
5. Regenerate frontend types.
6. Re-run the relevant checks.

### Security

Never paste real customer documents, credentials, API keys, or `.env` contents into hosted AI agents. Use fake development data.

Treat authorization, private document storage, audit logging, masking sensitive identifiers, and payment idempotency as required security controls—not optional enhancements.
