# claude-kit

My shared Claude Code skills and agents, kept in one git repo and symlinked into `~/.claude` so every project gets them and a fix lands everywhere at once.

## What is in it

| Kind | Name | What it does |
|---|---|---|
| Skill | `make-long-video` | Makes a long-form (default pt-BR, programming) YouTube video end to end: trends, plan, script, ElevenLabs voice, Manim scenes, ffmpeg assembly, packaging, anti-slop check. Resumable per video. |
| Skill | `keep-feature-context` | Cross-session feature memory: a living log per feature (`new`, `resume`, `done`). |
| Agents (video) | `video-researcher`, `video-scriptwriter`, `video-animator`, `video-producer` | The role subagents `make-long-video` delegates to. Only used by that skill. |
| Agents (dev team) | `team-leader`, `architect`, `swe`, `qa`, `reviewer` | One generic team, one source of truth. `team-leader` runs as the main session and orchestrates; `architect` grills ideas and writes the plan; `swe` implements one task per worktree and opens a PR; `qa` verifies and answers `QA: GOOD TO GO`/`BLOCKED`; `reviewer` reviews (security, smells, conventions) and merges only when allowed. Project specifics (stack, gates, e2e tools, branch naming) are read from the project's `AGENTS.md`/`CLAUDE.md`. |

## Install

```bash
git clone <this repo> ~/Projects/claude-kit   # or use your existing copy
~/Projects/claude-kit/install.sh
```

`install.sh` first installs/upgrades [tether](https://pypi.org/project/tether-sdk/) (`uv tool install --upgrade "tether-sdk[mcp]"`), adds the `nvidia` provider and the `tether` MCP server if missing (export `NVIDIA_API_KEY`). `swe` codes through tether on `nvidia/z-ai/glm-5.3-flash`; every other agent uses the default Claude subagent. Then it symlinks each `skills/<name>/` dir and each `agents/*.md` file into `~/.claude/skills/` and `~/.claude/agents/`. Safe to rerun; it never overwrites a real file (it prints `SKIPPED` instead). Start a new Claude Code session afterwards: skills and agents are discovered at session start.

Check: `ls -l ~/.claude/skills ~/.claude/agents` should show arrows into this repo.

## Use

### make-long-video
Run it from the project root of your channel project (it writes `videos/`, `video-kit/`, `preferences.json` there).

```
/make-long-video interview                  # once per project: saves preferences.json (voice, tone, mascot, ...)
/make-long-video auto 6 velocity=slow       # trending topics, 6 min, one subagent at a time
/make-long-video "Docker multi-stage builds" 8 velocity=fast
/make-long-video resume                     # list unfinished videos and continue one
/make-long-video help
```

Needs `ELEVENLABS_API_KEY` in your environment (`~/.profile`), `ffmpeg`, and Manim system libs (preflight tells you the `apt` command). Project-specific choices (voice id, palette, mascot, joke bank, CTA) belong in the project's `preferences.json`, never in the skill. See `skills/make-long-video/ISSUES.md` for known rough edges.

### keep-feature-context
```
/keep-feature-context new <name>   # start logging a feature (backfills what this session already did)
/keep-feature-context resume       # pick up an unfinished one
/keep-feature-context done         # wrap up and archive
```
On first use in a project it runs a preflight and writes the answers into the project's `AGENTS.md` (or `CLAUDE.md`). Code projects get a `## Dev team specifics` section (stack, check commands, e2e/QA, branch/PR style, delivery mode, hard stops, design docs, log location) that the dev-team agents read. Other projects (video, content, notes, with or without git) get only a short `## Feature context` section: what the project is and where logs go.
Where logs live is resolved per project: a path named in the project's `CLAUDE.md`/`AGENTS.md`, else `<repo>/.claude/feature-context/` (committed, default for new projects), else an existing legacy `~/.claude/projects/<repo>/feature-context/`.

### Dev team (team-leader, architect, swe, qa, reviewer)
Start the orchestrator as the main session: `claude --agent team-leader` (or pick it in the agent UI). It delegates to the others through the Agent tool. Flow: idea -> `architect` (questions relayed to you, then a plan) -> `swe` per task -> `qa` + `reviewer` on the PR -> merge. It also logs with `keep-feature-context`.
Put the project's rules in its `AGENTS.md`/`CLAUDE.md` (test and coverage gates, e2e/runbooks, branch and commit style, whether to use waves or an integration branch). To customize one role for one project, add `.claude/agents/<role>.md` there; project agents win over global ones. Model choice is not pinned in the kit; set `model:` in a project override if you want to cap cost.

## Layout

```
claude-kit/
├── README.md        this file
├── AGENTS.md        setup instructions for an AI agent (or you) configuring a machine/project
├── install.sh       symlinks skills/ and agents/ into ~/.claude
├── skills/<name>/   one dir per skill (SKILL.md plus helper scripts)
└── agents/*.md      one file per agent
```

## Adding or changing things

- Edit the file here, commit, done: symlinks mean `~/.claude` sees it immediately (new session for new files).
- New skill: add `skills/<name>/SKILL.md`, rerun `install.sh`. New agent: add `agents/<name>.md`, rerun `install.sh`.
- Keep project facts out. If something only makes sense for one project, it goes in that project's `CLAUDE.md`/`AGENTS.md`/`preferences.json`.

## Precedence gotchas

- Same-named **skills**: a global (`~/.claude/skills`) skill takes precedence over a project's `.claude/skills/<same name>`. Once installed, the kit version shadows old per-project copies. Delete those copies when you are ready.
- Same-named **agents**: the project's `.claude/agents/` wins over global ones.
- `~/.claude/skills/synced/` is account-synced and namespaced (`anthropic-skills:`); it does not conflict.
