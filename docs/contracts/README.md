# API contract

`openapi.json` here is generated from the FastAPI app and committed. It is the
boundary between backend and frontend.

- Only the project owner commits changes to this folder.
- Regenerate: `python scripts/export_openapi.py`
- Review the diff (`git diff docs/contracts/openapi.json`) before committing.
  Removed or renamed fields/routes are breaking changes. Added optional ones are fine.
- Frontend regenerates types from it: `bash scripts/gen_frontend_api.sh`

Optional second file, `permissions.md`: the role/permission matrix from section 2 of
the requirements document, written as a table. Backend implements it; reviewer checks it.
