# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Tracks zsh config (`.zshrc`, `.zshenv`, `.zprofile`) with a per-machine `.local` override pattern for secrets and machine-specific config. Bootstrap script also handles cloning a private Claude Code config repo.

## Layout

```
.
├── install.sh    Bootstrap: stow + .local seeding + Claude config clone
├── zsh/          Stow package: .zshrc, .zshenv, .zprofile -> $HOME
├── test/         Docker-based test harness for install.sh
├── .gitignore    Excludes *.local files and OS junk
├── AGENTS.md     Rules for LLM-based CLI agents (Claude Code, Cursor, etc.)
└── README.md
```

## First-time setup on a new machine

```bash
git clone git@github.com:uz1pk/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` will:

1. Install GNU Stow if missing (Homebrew on macOS, apt on Debian/Ubuntu)
2. Symlink every package into `$HOME` (currently `zsh/` only)
3. Create empty `~/.zshrc.local`, `~/.zshenv.local`, `~/.zprofile.local` (mode 600) if missing
4. Prompt for a Claude Code config repo URL — or read `$CLAUDE_REPO` env var — and clone into `~/.claude`
5. Warn if the `claude` CLI isn't in PATH

Re-runs are idempotent: existing `.local` files are never overwritten, and `~/.claude` is left alone if already cloned.

After bootstrap, populate the three `~/.X.local` files with your machine-local config (typically pasted from a password manager).

## The `.local` override pattern

Each tracked zsh file ends with a line like:

```bash
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
```

If `~/.zshrc.local` exists, zsh sources it after the tracked file. Same pattern for `.zshenv` and `.zprofile`. The `.local` files are gitignored (via `*.local`) and live only on the local machine. Use them for anything machine-specific: API tokens, work-only aliases, internal URLs, etc.

## Day-to-day workflow

`~/.zshrc` is a symlink to `~/dotfiles/zsh/.zshrc` — they are the same file. Edit through either path; your editor and git both see the change.

```bash
$EDITOR ~/.zshrc                                  # make the change
cd ~/dotfiles && git diff                         # review
git add zsh/.zshrc && git commit -m "..." && git push
```

## Adding a new stow package

```bash
mkdir -p ~/dotfiles/<tool>            # e.g. tmux, git, nvim
mv ~/.<configfile> ~/dotfiles/<tool>/  # move the config in
cd ~/dotfiles && stow <tool>          # symlink it back into $HOME
```

`install.sh` will pick up the new package automatically on the next run.

## Testing

```bash
./test/run.sh
```

Spins up a clean Ubuntu 22.04 container, runs `install.sh`, and asserts:

- All three symlinks land at the right paths
- `.local` files are created with mode 600
- `test/` is correctly excluded from stowing
- The tracked `.zshrc` is syntactically valid zsh
- Re-running preserves existing `.local` files
- `$CLAUDE_REPO` triggers a clone into `~/.claude`
- `install.sh` leaves an existing `~/.claude` alone
- A failing clone produces a `WARNING` and exits 0 (doesn't abort the rest of the bootstrap)

Re-run after any change to `install.sh` or the stow packages.
