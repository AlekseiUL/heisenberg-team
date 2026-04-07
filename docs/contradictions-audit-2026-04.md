# Documentation Contradictions Audit (2026-04)

## Why this file exists

During repository review we found multiple contradictions between setup scripts, architecture docs, role docs, and examples.  
This note records what was inconsistent and what was normalized.

## Resolved contradictions

### 1) OpenClaw ID path vs character folder path

- **Before:** `configs/README.md` used `~/.openclaw/agents/heisenberg/openclaw.json`.
- **After:** examples now use OpenClaw agent IDs (`main`, `producer`, `teamlead`, ...), e.g. `~/.openclaw/agents/main/openclaw.json`.

### 2) `trash-agent-session.sh` examples used character names

- **Before:** `docs/api-reference.md` showed `bash scripts/trash-agent-session.sh walter`.
- **After:** example uses `teamlead` (the real OpenClaw ID).

### 3) Conflicting model statements in configs docs

- **Before:** `configs/README.md` mixed fixed model claims ("All others use Sonnet") with env-driven placeholders.
- **After:** docs now state model values come from `.env` (`MAIN_MODEL`, `COORDINATOR_MODEL`, `TECH_MODEL`, `WORKER_MODEL`).

### 4) Heisenberg marked as coordinator in architecture docs

- **Before:** `README.md`, `README.ru.md`, and `assets/architecture.mmd` used "Boss & Coordinator".
- **After:** updated to "Boss & Escalation" to match Board-First coordination by `producer`.

### 5) Skill count mismatch (34 vs 33)

- **Before:** root READMEs claimed 34 skills while `skills/README.md` listed 33 shared skills.
- **After:** root READMEs now consistently use 33.

### 6) Incomplete agent list in session reset script help

- **Before:** `scripts/trash-agent-session.sh` help text omitted `main` and `researcher`.
- **After:** help text lists all active OpenClaw IDs.

### 7) Workspace path rule vs setup behavior

- **Before:** constitution said "never files in `~/.openclaw/agents/`", which conflicted with setup scripts that install runtime files there.
- **After:** wording clarifies: no project files in `~/.openclaw/agents/`, runtime OpenClaw files are allowed.

### 8) Skill ownership inconsistencies (`quality-check`)

- **Before:** ownership was split across role docs (`producer`, `teamlead`, `kaizen`) with conflicting wording.
- **After:** docs were aligned to constitutional ownership (`producer` handles OTK/quality-check).  
  `docs/agent-roles.md` and `agents/walter/AGENTS.md` were normalized.

### 9) Missing researcher row in modular constitution map

- **Before:** `references/constitution/02-errors.md` omitted explicit `researcher` row in the agent→skills table.
- **After:** row was added for parity with main constitution and role docs.

## Source of truth after normalization

- **Team protocol and routing:** `references/team-constitution.md`
- **OpenClaw API mechanics / skill invocation:** `docs/api-reference.md`
- **Installation behavior:** `scripts/setup.sh`, `scripts/setup-wizard.sh`, `SETUP.md`
- **Skill catalog count and dependencies:** `skills/README.md`

## Notes

- This file is a changelog-style audit note and should be updated if new contradictions are found.
