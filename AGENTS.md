# Agent Guidelines

Rules for LLM-based CLI agents (Claude Code, Cursor, Aider, Cline, etc.) working in this repo. Explicit user instruction overrides these rules.

## Context

This is a **public** dotfiles repo on github.com. Anything committed is world-readable and permanent — forks, secret-scanning archives, and mirrors retain history even after force-push or repo deletion.

## Hard rules

Never do any of the following without explicit user instruction.

### Secrets

1. **Don't write secrets to tracked files.** API keys, tokens, private keys, passwords — none of them belong in `zsh/*`, `install.sh`, this file, or anywhere else tracked. Real values live in `~/.zshrc.local`, `~/.zshenv.local`, `~/.zprofile.local`, or other gitignored files under `$HOME`.

2. **Don't ask the user to paste a secret into chat.** To verify a credential, check existence or structure (`echo "${#TOKEN}"`, JWT segment count), never the literal value.

3. **Don't echo, `cat`, or print secrets to the terminal.** Scrollback is a leak vector.

4. **Don't stage or commit `*.local` files.** If one ever appears staged, `git restore --staged` it and flag it.

### Identifying info

5. **Don't hardcode private hostnames, repo URLs, usernames, account/cluster names, or anything else that fingerprints the user or their systems** into tracked files. Such values go in `~/.zshrc.local` or are supplied at runtime via env var or interactive prompt. This includes the Claude config repo URL used by `install.sh` — it's read from `$CLAUDE_REPO` or prompted, never hardcoded.

### History

6. **Don't `git push` without explicit confirmation.** Pushes to this repo are permanent and world-visible.

7. **Don't force-push or rewrite history on `main`** without explicit instruction.

## Conventions

- **`.local` override pattern**: each tracked `zsh/.X` ends with `[ -f "$HOME/.X.local" ] && source "$HOME/.X.local"`. Machine-specific config goes in the `.local` counterpart, which lives in `$HOME` outside this repo's tree.

- **`install.sh` is idempotent.** `.local` files are never overwritten; `~/.claude` isn't re-cloned if already a git repo; an existing untracked `~/.claude/` is backed up to `~/.claude.backup-YYYYMMDD-HHMMSS` before a fresh clone. Don't weaken these guards.

- **Tests** live in `test/` and run via `./test/run.sh`. Run them after changes to `install.sh` or `zsh/` before recommending commit. They don't need network access to internal hosts.

- **GNU Stow symlinks**: editing `~/.zshrc` edits `zsh/.zshrc` (same file, two paths). Don't try to "sync" — just edit one path.

## When in doubt

If an action might leak sensitive info or push something to the public repo that shouldn't be there: **don't, and ask.** Pausing is cheap; a public leak means credential rotation plus permanent partial disclosure.
