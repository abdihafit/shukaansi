# Persistent Project Memory

This repository uses an external Obsidian-compatible Markdown vault for persistent development memory. Normal session context/compaction remains separate; these notes are not a transcript archive.

Vault: `C:\Users\ADMIN\Documents\CodexVault`

Project memory: `C:\Users\ADMIN\Documents\CodexVault\Projects\kulmee`

## Before substantial work

1. Read CURRENT_STATE.md (the primary recovery checkpoint).
2. Read PROJECT.md.
3. Read relevant sections of ARCHITECTURE.md.
4. Search DECISIONS.md when making architectural/product decisions.
5. Search BUGS_AND_SOLUTIONS.md when investigating recurring problems.
6. Check BACKLOG.md for outstanding work.

Retrieve only relevant context; do not load the entire archive unnecessarily. If the external vault is unavailable, report that limitation and use verified repository evidence; do not claim memory was read or updated.

## After substantial work

1. Update CURRENT_STATE.md with the date and latest verified checkpoint.
2. Update ARCHITECTURE.md only if architecture changed.
3. Add DECISIONS.md entries only for significant decisions.
4. Add meaningful reusable resolved bugs to BUGS_AND_SOLUTIONS.md.
5. Update CHANGELOG.md for meaningful completed work, not every commit.
6. Update BACKLOG.md when task status changes; do not invent features.
7. Create a concise sessions/YYYY-MM-DD-short-description.md for substantial development sessions, using Objective, Work Completed, Important Decisions, Problems Encountered, Files Significantly Changed, Remaining Work, and Recommended Next Step sections.

Memory must describe reality. Never claim implementation without verifying code; distinguish implemented behavior from planned work and untested behavior. Use `Unknown — requires confirmation.` for unknown facts. Preserve the existing note headings and entry formats.

Prefer updating an existing entry over adding duplicates. Update stale checkpoints, mark superseded decisions, and move genuinely obsolete long-form material to archive/ when necessary. Preserve historically important decisions.

## Security and retention

Never write secret values into the vault: passwords, API keys, access/refresh tokens, private keys, Firebase service-account credentials, .env values, signing credentials, Android keystore passwords, Apple certificates/provisioning credentials, database passwords, OAuth client secrets, or payment-provider secrets. Record only configuration names and requirements, never values.

Do not persist full conversations, every message, raw chain-of-thought, or internal reasoning. Persist only useful architecture, significant decisions, implementation state, meaningful bugs/solutions, important dependencies/integrations, constraints, unresolved problems, major completed work, and next steps.

## Search and conflicting information

Before asking the user about potentially documented information, search memory, search the repository, and compare notes against code. Ask only when the answer cannot be reliably determined.

Prefer this memory search order: CURRENT_STATE.md, PROJECT.md, DECISIONS.md, ARCHITECTURE.md, BUGS_AND_SOLUTIONS.md, BACKLOG.md, sessions/, archive/.

For determining existing implementation facts, use this evidence priority:

1. Current repository/code.
2. Current configuration.
3. Explicit user information in the current session.
4. PROJECT.md / CURRENT_STATE.md.
5. ARCHITECTURE.md / DECISIONS.md.
6. Session archives.
7. Older archived documentation.

This evidence order does not override current user instructions about desired work or scope. If notes conflict with the repository, use the repository for implementation facts and explicitly flag the discrepancy. Never silently resolve an important contradiction.

## Setup scope

The 2026-09-25 memory setup is documentation-only: no application source, dependencies, Firebase/Flutter/platform settings, package names, build files, or deployment configuration changes. Further application work requires the user's next instruction.
