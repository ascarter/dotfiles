# Copilot Instructions

Use `AGENTS.md` as the single source of contributor and repository policy context.

## Required Load Order
1. Read `AGENTS.md` first.
2. Follow links from `AGENTS.md` to supporting docs in `docs/` only when more detail is needed.
3. If there is a conflict, treat `AGENTS.md` as authoritative and align the other doc.

## Quick Validation Commands
- `./test.sh` for install/sync smoke testing.
- `bin/dotfiles status` to verify symlink/state drift.

## Scope
This file is intentionally minimal to avoid duplicated guidance and drift. All architecture, style, lifecycle, and policy details should be maintained in `AGENTS.md` and its linked supporting documents.
