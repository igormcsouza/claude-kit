# AGENTS.md: setting up claude-kit

Instructions for an AI agent (or a human) setting up this kit on a machine or in a project.

## Rules
- This repo is the single source of truth for shared skills (`skills/`) and agents (`agents/`). Never copy them into a project; symlink via `install.sh`.
- Do not put project-specific facts in here (voices, paths, repo names, channel names). Those go in the consuming project.
- Never delete a per-project copy of a skill or agent unless the user asked for that specific removal. Do not modify other repos as part of setup.

## One-time machine setup
1. Clone or locate this repo (usually `~/Projects/claude-kit`).
2. Run the installer:
   ```bash
   ./install.sh
   ```
   It creates:
   - `~/.claude/skills/<skill>` -> `<kit>/skills/<skill>` (one symlink per skill dir)
   - `~/.claude/agents/<agent>.md` -> `<kit>/agents/<agent>.md` (one symlink per agent file)
3. Verify: `ls -l ~/.claude/skills ~/.claude/agents` shows links into the kit, and no `SKIPPED` lines were printed. A `SKIPPED` line means a real file/dir with that name already exists; ask the user before moving it.
4. Tell the user to start a new Claude Code session (skills and agents load at session start).

Manual equivalent for one skill and one agent:
```bash
ln -s ~/Projects/claude-kit/skills/keep-feature-context ~/.claude/skills/keep-feature-context
ln -s ~/Projects/claude-kit/agents/architect.md ~/.claude/agents/architect.md
```

## Per-project setup
Nothing to symlink: global skills and agents apply to every project. Do only what the skill needs:

- **make-long-video**: run from the channel project root. Create the project's `preferences.json` with `/make-long-video interview` (voice and `voice_id`, mascot, palette, joke bank, CTA, defaults). Preflight creates `./video-kit/` and `videos/` there. Ensure `ELEVENLABS_API_KEY` is in the user's environment; never print or commit it. Add `video-kit/.venv/` to the project's `.gitignore`.
- **keep-feature-context**: its preflight creates/updates the `## Dev team specifics` section in the project's agents file by asking the user; do not invent answers. Default store is `<repo>/.claude/feature-context/{active,archive}/`; create it with `.gitkeep` files if the team wants it committed. To use a different location, add one line to the project's `CLAUDE.md` or `AGENTS.md` such as `feature-context store: <path>`. A project that already has logs in `~/.claude/projects/<repo>/feature-context/` keeps working without changes.
- **Dev team agents** (`team-leader`, `architect`, `swe`, `qa`, `reviewer`): rely on the project's `AGENTS.md`/`CLAUDE.md` for stack, test/coverage gates, e2e runbooks, branch/commit style and delivery mode (PR per task vs waves). Make sure those are documented there. To customize a role for one project, add `.claude/agents/<role>.md`; the project copy wins. Run the orchestrator with `claude --agent team-leader`.

## Migrating a project off its own copy
Only when the user asks, one project at a time:
1. Confirm `install.sh` ran and the global skill/agent is visible in a new session.
2. Diff the project copy against the kit version (`diff -r`) and port any wanted differences into the kit first.
3. Remove the project copy (and any `.agents/skills/<name>` symlink that pointed at it), commit.

## Changing the kit
Edit files here, commit, push. Run `bash -n` on shell scripts and `python3 -m py_compile` on Python scripts before committing. New skill or agent: add the file, rerun `./install.sh`.
