# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview
- `index.html` contains the full front-end application (HTML/CSS/JS in one file).
- `deploy.sh` is the canonical deployment path and generates runtime server/container files.
- `README.md` and `LICENSE` should be kept current for distribution.

## Working conventions
- Keep changes minimal and focused on the requested task.
- Prefer readability over abstraction for this small project.
- If editing UI behavior, preserve touch-first ergonomics and existing keyboard controls.
- Avoid introducing build tooling unless explicitly requested.

## Validation checklist
- Run at minimum:
  - `bash -n deploy.sh`
  - `git status --short`
- If JavaScript/HTML logic is changed, do a quick manual browser sanity check when possible.

## Documentation expectations
- Update `README.md` when controls, deployment flow, or user-facing behavior changes.
- Keep license metadata accurate.

## Commit and PR etiquette
- Use descriptive commit messages with a clear scope (`docs:`, `fix:`, `feat:`).
- Summarize what changed and why in PR descriptions.
