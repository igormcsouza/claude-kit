# make-long-video: known issues / to review

Shared across projects; project-specific findings belong in that project, not here.

1. **Duplicate synced skill (account-level).** `~/.claude/skills/synced/*/make-long-video/` (listed as `anthropic-skills:make-long-video`) is an old account-synced copy (no velocity/resume/interview/subagents). Namespaced, so `/make-long-video` should hit this local one, but verify. Real removal: delete the skill in claude.ai settings (local copy is managed by sync and would come back).
2. **Never run end to end.** Only `preflight.sh` and `state.py` were tested. No Manim render, no TTS run. Kit templates (`common.py`, `code_diff`, `flow`, `reveal`, `terminal`, `chart`, `meme_card`, `hero`) do not exist yet; the animator builds them on first run (likeliest failure point). Do a 2-min `velocity=slow` test run.
3. **TTS needs internet and a paid key.** ElevenLabs v4 (~$0.45 per 6 min).
4. **Subagent permissions.** Background subagents may stall on Bash/Write prompts. Allow `manim`, `ffmpeg`, `uv run`, `state.py` in settings (try `/fewer-permission-prompts`).
5. **(Resolved by the claude-kit layout.)** Role agents are global (`~/.claude/agents`, symlinked); preflight no longer copies them into projects. A project can still override a role with its own `.claude/agents/video-<role>.md`.
6. **Fast-mode collisions.** Parallel animators may clash on Manim's shared `media/` cache. Give each its own `--media_dir`.
7. **`topics.log` is per project** (`videos/topics.log`), so topic dedup is not global.
8. **Quality unverified.** Contact sheet only catches layout. Joke quality and pt-BR pronunciation need human ears; draft review is the real check.
9. **Voices.** Voice name/`voice_id` now come from the project's `preferences.json`; the TTS engine (ElevenLabs v4, OpenAI fallback) is still hardcoded in the skill.

## Updated after the first full run (2026-10-10)
- Item 2 is outdated: a full video was produced end to end (kit templates are built by the animator on first run; they live in `video-kit/`).
- Item 8 still true: audio quality, intonation and jokes need the user's ears. Pronunciation is checked by ear; timing comes from ElevenLabs alignment.
- Cues come from ElevenLabs `/with-timestamps` alignment (no ASR).
- Voice is now chosen by an A/B excerpt; default is ElevenLabs v4 Jessica; keys never go in chat.
- Draft clips are ~180 kbps and look soft; blocky/corrupt playback on a laptop was the player's hardware decode (VLC `--avcodec-hw=none`), not the file.
- Agents added mid-session are not registered until a new session; use `general-purpose` + role brief file.
