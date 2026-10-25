# Running four AI agents in parallel on the CSC CRM

Backend, frontend, integration and review agents each work in their own folder, on their
own branch, in their own editor window. They meet only through two things you control:
the API contract (`docs/contracts/openapi.json`) and your merges into `main`.

## 1. What goes where

| File | Place in repo | Purpose |
|---|---|---|
| `AGENTS.md` | repo root | Rules every agent reads first |
| `backend/AGENTS.md` | `backend/` | Backend agent rules (FastAPI layering) |
| `frontend/AGENTS.md` | `frontend/` | Frontend agent rules |
| `docs/contracts/README.md` | `docs/contracts/` | How the contract works (`openapi.json` appears here after step 4) |
| `docs/reviews/README.md` | `docs/reviews/` | Where the review agent writes findings |
| `docs/SETUP-AI-WORKFLOW.md` | `docs/` | This file |
| `scripts/check.sh` | `scripts/` | The "am I done?" command for every agent |
| `scripts/check_ownership.sh` | `scripts/` | Blocks edits outside your own folder |
| `scripts/export_openapi.py` | `scripts/` | FastAPI app -> `docs/contracts/openapi.json` |
| `scripts/gen_frontend_api.sh` | `scripts/` | `openapi.json` -> TypeScript types |
| `scripts/mock_api.sh` | `scripts/` | Fake API on port 4010 from the contract |
| `scripts/worktrees.sh` | `scripts/` | Creates one folder + branch per agent |
| `.github/workflows/ownership.yml` | `.github/workflows/` | Runs the ownership check on pull requests |
| `.github/CODEOWNERS` | `.github/` | Edit the username placeholder |

If your repo already has files at any of these paths (especially under `.github/`), merge by hand.

## 2. One-time setup (you, on `main`)

```bash
# from the repo root, with the bundle unzipped on top of it
mv CSC_CRM_Development_Documentation_v1.0.docx docs/      # keep the requirements doc in docs/
chmod +x scripts/*.sh scripts/*.py
# edit .github/CODEOWNERS: replace YOUR_GITHUB_USERNAME

# tools (all free)
cd backend && python -m venv .venv && .venv/bin/pip install ruff mypy pytest bandit pip-audit && cd ..
cd frontend && npm ci && npm i -D openapi-typescript && cd ..
pip install semgrep            # optional, repo-wide scan
brew install gitleaks          # optional, secrets scan (macOS)

# .gitignore must cover: .env  .env.*  frontend/.env.local  node_modules  dist  __pycache__  .venv
git checkout -b owner/setup && git add -A && git commit -m "Add AI workflow setup" 
git checkout main && git merge owner/setup
```

Add `backend/.env.example` with safe dummy values (fake DB URL, fake secret). Agents and worktrees
use it; the real `.env` stays out of reach.

## 3. Phase 0: lock the contract (you + one model, before parallel work)

1. Backend agent (alone): create Pydantic schemas and route stubs for the first slice
   (auth, customers, services, jobs) following the requirements doc, section 10.
2. `python scripts/export_openapi.py` and review `git diff docs/contracts/openapi.json`.
3. Add `docs/contracts/permissions.md` (role matrix from section 2 of the requirements doc).
4. Commit these to `main` on an `owner/*` branch. **From now on the contract changes only when you re-export it.**

## 4. Start the parallel agents

```bash
bash scripts/worktrees.sh setup
```
This creates sibling folders next to your repo: `<repo>-backend`, `<repo>-frontend`,
`<repo>-integration`, `<repo>-review`, each on its own branch.
Then in each:
- backend: `cd backend && python -m venv .venv && .venv/bin/pip install -r requirements.txt`, copy `.env.example` to `.env`
- frontend: `cd frontend && npm ci`, create `.env.local` with `VITE_API_URL=http://localhost:4010`

`node_modules`, `.venv` and `.env` files are not shared between worktrees.
Open each folder as its own project/window. Never open the same folder in two agent windows.

| Window | Model (free) | Fallback when quota ends |
|---|---|---|
| backend | Claude Opus 4.6 (Antigravity) | GLM / Kimi / DeepSeek via Kilo |
| frontend | Gemini 3.8 Flash (Antigravity) | Qwen3 Coder / DeepSeek via Kilo |
| integration | Claude Sonnet 4.6 (Antigravity) | same as backend |
| review | GPT-OSS-120B (Antigravity) | DeepSeek / GLM via Kilo |

Check your model picker; free lists change. Third-party models in Antigravity may be removed on 2 Nov 2026.
These tools generally read `AGENTS.md`; if one does not, paste its contents into that tool's rules/custom-instructions box.

### First prompt for each window
**Backend**
> Read AGENTS.md and backend/AGENTS.md. Implement <module> following docs/CSC_CRM_Development_Documentation_v1.0.docx and docs/contracts/openapi.json. Keep api->services->repositories layering, put permission checks in services, add pytest for each service including a permission-denied case. Run scripts/check.sh backend and report results. Do not touch other folders.

**Frontend**
> Read AGENTS.md and frontend/AGENTS.md. Generate API types with scripts/gen_frontend_api.sh and run the mock API with scripts/mock_api.sh. Build <screen> per the requirements doc section 3, with loading, empty and error states. Run scripts/check.sh frontend and report. Do not touch backend/.

**Integration** (only after backend + frontend merged to main)
> Read AGENTS.md. Run the real backend and frontend together. Fix only mismatches between them and failing tests. No new features. Run scripts/check.sh all and report.

**Review**
> Read AGENTS.md and docs/CSC_CRM_Development_Documentation_v1.0.docx sections 2, 11 and 13. Review <branch/module> for authorisation gaps, missing audit logging, data exposure, injection, file-upload handling, idempotency and spec drift. Do NOT edit code. Write findings (file, line, how to trigger, suggested fix) to docs/reviews/<date>-<topic>.md.

## 5. Daily loop

1. Agent works on its branch, runs `scripts/check.sh <backend|frontend>`, commits.
2. Before opening a pull request, run `bash scripts/check_ownership.sh` locally. CI runs it too.
3. You review and merge. **Merge order: backend, then (you) re-export the contract, then frontend, then integration.**
4. After a backend merge, in the frontend worktree: `git merge main` then `bash scripts/gen_frontend_api.sh`. TypeScript errors now point at any mismatch.
5. Review agent runs on merged `main` code; owners fix findings on their own branches.

If an agent needs a contract change: it writes the request in its reply; you decide, change it, re-export, commit.

## 6. GitHub settings (once)
Settings -> Branches -> protect `main`: require pull requests, require the `ownership-check`
status, and require review from Code Owners. Without this the rules are only advice.

## 7. Troubleshooting
- **export_openapi.py fails**: the app needs env vars or a database at import time. Move that work to startup/lifespan or export dummy env vars from `.env.example` first.
- **"branch already checked out"**: a branch can live in only one worktree. Use `git worktree list`.
- **Database**: run one dev Postgres (from `compose.yaml`) and point all worktrees at it; only the backend worktree runs migrations.
- **Agent wandered into another folder**: `git diff --stat main` shows it; revert those files, tighten the prompt.
- **Never** paste real customer documents or `.env` contents into any agent, especially free hosted models, which may log prompts.
