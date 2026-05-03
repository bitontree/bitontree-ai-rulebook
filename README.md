# Bitontree AI Rulebook

Org-wide engineering standards. Auto-loaded by Claude Code (`CLAUDE.md`) and Codex (`AGENTS.md`) so that every AI-assisted change to a Bitontree project follows the same rules.

These rules apply to **everyone** — humans and AI assistants alike. The rulebook is the source of truth; project-level `CLAUDE.md` / `AGENTS.md` files may add specifics but cannot override the Hard Rules.

## What's in here

| Path | Purpose |
| --- | --- |
| [`CLAUDE.md`](CLAUDE.md) | Entrypoint Claude Code reads. The summary + Hard Rules. |
| [`AGENTS.md`](AGENTS.md) | Identical mirror of `CLAUDE.md` for Codex and other agents. |
| [`standards/`](standards/) | Stack-specific deep-dives (JS, React, Python, FastAPI/Flask, LangChain, security, testing, git). |
| [`templates/`](templates/) | Drop-in `.gitignore`, PR template, and a `commit-msg` hook that blocks AI co-author trailers. |
| [`scripts/`](scripts/) | Install + sync scripts. |

## Install (one-time, per engineer)

Clone this repo to a stable location — keep it forever. Future `git pull`s update the rules everywhere they're symlinked.

```bash
git clone <rulebook-url> bitontree-ai-rulebook
cd bitontree-ai-rulebook
```

Then run the installer for your platform.

### macOS / Linux

From a terminal:

```bash
./scripts/install-global.sh             # interactive
./scripts/install-global.sh --dry-run   # preview
./scripts/install-global.sh --force     # overwrite without prompting
```

Or **double-click** `scripts/install-global.command` in Finder. macOS opens it in Terminal automatically.

### Windows

From PowerShell (use `powershell.exe` or Windows Terminal — not legacy `cmd.exe`):

```powershell
.\scripts\install-global.ps1            # interactive
.\scripts\install-global.ps1 -DryRun    # preview
.\scripts\install-global.ps1 -Force     # overwrite without prompting
```

Or **double-click** `scripts\install-global.bat` in File Explorer.

> **Windows symlink prerequisite:** the script needs permission to create symbolic links. Enable **Developer Mode** once (Settings → Privacy & security → For developers → Developer Mode = On), or run PowerShell as Administrator. The script will tell you if neither is available and exit cleanly.

### What it does (both platforms)

The installer creates symlinks (so future `git pull`s update everywhere automatically):

- `~/.claude/CLAUDE.md` → `<repo>/CLAUDE.md`  (Claude Code loads automatically)
- `~/.codex/AGENTS.md` → `<repo>/AGENTS.md`  (Codex loads automatically)
- `~/.bitontree-hooks/commit-msg` → `<repo>/templates/commit-msg-hook`
- Sets `git config --global core.hooksPath ~/.bitontree-hooks`

On Windows the equivalents live under `%USERPROFILE%\.claude\`, `%USERPROFILE%\.codex\`, `%USERPROFILE%\.bitontree-hooks\`.

After that, every project on your machine inherits the rules and the commit-msg hook (which blocks AI co-author trailers and enforces Conventional Commits) — without needing to touch each project individually.

> The `commit-msg` hook is a bash script. On Windows it runs through Git Bash, which Git for Windows ships by default — no extra setup needed.

## Stay updated

```bash
cd ~/work/bitontree-ai-rulebook && git pull
```

That's it. Symlinks resolve to the new content automatically; no reinstall needed.

## Per-project files

The hooks and templates apply globally via the install above. If a *specific* project also wants in-tree copies (e.g. for repo-local CI):

- Copy [`templates/.gitignore`](templates/.gitignore) into the project root and adapt.
- Copy [`templates/pull_request_template.md`](templates/pull_request_template.md) to `.github/pull_request_template.md`.
- The `commit-msg` hook is already enforced globally; no per-project copy needed.

## Editing the rulebook

1. Branch off `main`: `git checkout -b feat/BIT-XXXX-rulebook-update`
2. Edit `CLAUDE.md` (the source) and/or files under `standards/`.
3. Run the sync script so `AGENTS.md` stays byte-identical with `CLAUDE.md`:
   - macOS / Linux: `./scripts/sync.sh`
   - Windows: `.\scripts\sync.ps1`
4. Open a PR. Standards changes need at least one reviewer from the engineering leadership group.

CI runs the equivalent `--check` / `-Check` mode to fail any PR where `CLAUDE.md` and `AGENTS.md` have drifted.

## Mandated tooling (quick reference)

| Stack             | Tool     |
| ----------------- | -------- |
| Node.js packages  | **npm**  |
| Python env + deps | **uv**   |
| JavaScript tests  | **Jest** |
| Python tests      | pytest   |

Languages: JavaScript (TypeScript preferred) and Python only.

## The seven Hard Rules (non-negotiable)

1. No AI co-authorship in commits.
2. No secrets in commits.
3. No force-push to protected branches.
4. No bypassing git hooks.
5. No direct pushes to protected branches — every change is a PR.
6. No silencing of lint, type, or test failures.
7. No rewriting of shared git history.

Full text: [`standards/00-hard-rules.md`](standards/00-hard-rules.md).

## Questions / disagreements

Open a PR proposing the change. Disagreement is fine; silent deviation is not.
