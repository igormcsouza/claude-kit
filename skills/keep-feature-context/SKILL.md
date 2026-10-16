---
name: keep-feature-context
description: Cross-session feature memory. `/keep-feature-context new <name>` starts a living log; once active, log every PO request, decision, problem and step automatically; `done` wraps up and archives; `resume` lists unfinished contexts to pick up. Use whenever the user wants to preserve context across sessions.
---

# keep-feature-context

Living log so work survives session changes.

## Preflight (run first, on every command)
This skill (and the dev-team agents `team-leader`, `architect`, `swe`, `qa`, `reviewer`) read project specifics from the project's agents file. Make sure they are written down before doing anything else. Project root = repo root if inside a git repo, else the nearest parent of the cwd holding `CLAUDE.md`/`AGENTS.md`, else the cwd.

1. Find the file at the project root: `AGENTS.md` (any case, e.g. `Agents.md`); else `CLAUDE.md`; else create `AGENTS.md`. Look for a `## Dev team specifics` section (code projects) or a `## Feature context` section (other projects). Either one means preflight was already done for that kind.
2. Decide the project kind. **Code project:** a git repo with code (Makefile, `package.json`, `pyproject.toml`, CI config, ...) or the user says it uses the dev team. **Other project:** anything else (content, video, research, notes; often not a git repo). If unclear, ask one question. Do not run the dev-team questionnaire for other projects.
3. If the matching section exists and covers every item for its kind, say nothing and continue. If missing or partial, list only the missing items.
4. Pre-fill what the repo already answers (Makefile, `package.json`, `pyproject.toml`, CI config, `git log`, `gh repo view`) and present those as proposed answers. Ask the user for the rest (AskUserQuestion when options are clear, else plain chat; at most 4 questions per round). Do not guess.
5. Write the answers into the section (add or edit only that section; keep the file's tone, never rewrite unrelated parts), show the user a 3-line summary of what changed, then continue with the command.

**Other projects** need only two items, written as a `## Feature context` section:
```markdown
## Feature context
- Project: <one line: what this is and what "a feature" means here>
- feature-context store: .claude/feature-context/   (use a path outside the project, or add it to .gitignore, if it must not be committed)
```

**Code projects**, items (one short line each):
- **Stack and layout:** languages, main packages/dirs, tooling (package manager, linter, type checker).
- **Check commands:** how to run lint, types, unit tests, and the coverage gate.
- **E2E / manual QA:** tool, folder, runbook for web/mobile/API, shared single-instance resources (ports, emulator).
- **Branch, commit and PR style:** branch naming, commit convention, PR title/body rules, who merges and the merge style.
- **Delivery mode:** one PR per task (default) or waves with an integration branch.
- **Environments and hard stops:** local fakes vs real cloud, what needs the user's OK (money, cloud resources, deleting data, force push, DNS).
- **Design docs / plan:** paths of the architecture doc, roadmap or plan the architect must read.
- **Feature-context store:** `.claude/feature-context/` (default, committed), or another path (see Store).

Template for the code-project section:
```markdown
## Dev team specifics
- Stack: ...
- Checks: lint `...`; types `...`; tests `...` (coverage gate: ...)
- E2E / QA: ...
- Branches/commits/PRs: ...; merged by ...
- Delivery: PR per task | waves via `<branch>`
- Hard stops (ask first): ...
- Design docs: ...
- feature-context store: .claude/feature-context/
```

## Store (resolve once per session, in this order)
`<root>` below is the project root defined in Preflight (works with or without git).
1. A path the project names in its `AGENTS.md` / `CLAUDE.md` (the `feature-context store:` line of `## Dev team specifics` or `## Feature context`). Use it as the store root.
2. `<root>/.claude/feature-context/` if it exists. **In-project store (default for new projects):** in a git repo it is committed, so local and cloud sessions share it.
3. Git repos only: legacy machine-local store, if it exists: `~/.claude/projects/<main repo path with / and . replaced by ->/feature-context/` (e.g. `-home-me-Projects-app`). Main repo root = `dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`, so all worktrees share one store.
4. None exists: create `<root>/.claude/feature-context/` (with `active/` and `archive/`) and tell the user where it is; offer to record that choice in the agents file.

```
<store>/
├── active/<slug>.md      # not done yet
└── archive/<slug>.md     # done
```

Never write secrets/credentials in logs. In a git repo with an in-repo store: commit + push the log with the branch you are working on (an uncommitted log is lost when a cloud container is reclaimed), and on `resume` first `git fetch` and check `main` and the current branch for newer logs. Without git, skip all of that; the log is just files.

## Commands (`$ARGUMENTS`)

### `new <name>`
1. slug = kebab-case of name (e.g. `hybrid-aws-deployment`). Refuse if `active/<slug>.md` exists (suggest `resume`).
2. Create `active/<slug>.md` from the template below. Fill Goal from the user's words; ask only if truly unknown.
3. **Backfill from this session.** If the conversation so far already holds work for this feature (requests, decisions, problems, steps, branches/PRs), write it into the log before continuing: PO requests under Requests, decisions under Decisions, problems under Problems, steps under Progress log, and the remaining work as Next steps. Prefix each backfilled entry with `(backfilled)` and use the real time when you know it, else the session date. Only what actually happened in this conversation: never invent, never read other sessions' transcripts. If nothing relevant happened yet, skip this step.
4. From now on in THIS session: **log automatically** (see Logging). Tell the user the file path and, if you backfilled, say so in one line.

### `resume`
1. List `active/*.md`: for each show slug, Goal (1 line), Status, last-updated, and the top 3 Next Steps.
2. Ask which to pick up (AskUserQuestion if ≤4, else plain list). If only one, still confirm.
3. Read the chosen file fully, summarize state to user in ≤10 lines (goal, decisions, open problems, next steps, open PRs/branches), set `Current session` in Sessions table, and resume **automatic logging** to it.

### `done`
1. Take the context being logged this session (ask if ambiguous).
2. Write a **Wrap-up** section: outcome, final decisions, PRs merged, follow-ups/known debt, lessons.
3. Set `Status: done`, `Closed: <date>`; move file to `archive/`.
4. Stop logging. Confirm path.

## Logging (automatic once a context is active/resumed)
Append (never rewrite history) to the file, newest last, timestamped `YYYY-MM-DD HH:MM`. Update at natural checkpoints — after each user request, decision, problem found/solved, agent report, PR opened/merged — and always before the session might end. Do it silently, no announcements beyond a one-line "logged".

| Section | Put here |
|---|---|
| **Requests** | Every PO request, close to verbatim, with the date |
| **Decisions** | Decision + why + alternatives rejected |
| **Problems** | Problem, root cause, resolution (or still open) |
| **Progress log** | Steps taken, agent dispatches/reports, PR/branch links, test results |
| **Next steps** | Rewrite as a current checklist (this one is mutable) |
| **State** | Header fields: Status, branches, PRs, running services needed |

Write facts a cold-start session needs: file paths, commands, branch names, PR numbers, gotchas. No secrets/credentials.

## Template
```markdown
# <Title>
- Slug: <slug>
- Status: active
- Started: <date>   Updated: <date>   Closed: —
- Branches / PRs: —

## Goal
## Requests
## Decisions
## Problems
## Progress log
## Next steps
- [ ]
## Sessions
| Date | Session note |
```
