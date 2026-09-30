#!/usr/bin/env bash
# Run install.sh in a clean Ubuntu container, assert symlinks, .local files, and Claude clone behaviour.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker build -q -t dotfiles-test "$REPO_ROOT/test" >/dev/null

docker run --rm -v "$REPO_ROOT:/dotfiles-src:ro" dotfiles-test bash -c '
set -euo pipefail

cp -r /dotfiles-src "$HOME/dotfiles"
cd "$HOME/dotfiles"

# Initial bootstrap: no TTY, no CLAUDE_REPO -> Claude clone silently skipped.
out=$(./install.sh 2>&1)
grep -q "Skipped Claude config clone" <<<"$out"
echo "  OK  fresh install skips Claude clone when no env var/TTY"

for f in .zshrc .zshenv .zprofile; do
    [[ -L "$HOME/$f" && "$(readlink "$HOME/$f")" == *dotfiles/zsh/$f ]]
    echo "  OK  ~/$f -> dotfiles/zsh/$f"
done

for f in .zshrc.local .zshenv.local .zprofile.local; do
    [[ -f "$HOME/$f" && "$(stat -c %a "$HOME/$f")" == 600 ]]
    echo "  OK  ~/$f mode 600"
done

[[ ! -e "$HOME/Dockerfile" && ! -e "$HOME/run.sh" ]]
echo "  OK  test/ not stowed"

zsh -n "$HOME/.zshrc"
echo "  OK  .zshrc syntax valid"

# .local files preserved on rerun
for f in .zshrc.local .zshenv.local .zprofile.local; do echo MARKER > "$HOME/$f"; done
./install.sh >/dev/null
for f in .zshrc.local .zshenv.local .zprofile.local; do
    [[ "$(cat "$HOME/$f")" == MARKER ]]
    echo "  OK  ~/$f preserved on rerun"
done

for f in .zshrc .zprofile; do rm "$HOME/$f"; echo "preexisting $f" > "$HOME/$f"; done
out=$(./install.sh 2>&1)
for f in .zshrc .zprofile; do
    [[ -L "$HOME/$f" && "$(readlink "$HOME/$f")" == *dotfiles/zsh/$f ]]
    backup=$(ls -d "$HOME/$f".backup-* | head -1)
    [[ "$(cat "$backup")" == "preexisting $f" ]]
    grep -q "Moved existing ~/$f to" <<<"$out"
    echo "  OK  preexisting ~/$f backed up and replaced by symlink"
done
out=$(./install.sh 2>&1)
if grep -q "Moved existing" <<<"$out"; then
    echo "  FAIL  rerun moved files although links were in place"; exit 1
fi
echo "  OK  rerun with links in place moves nothing"

# CLAUDE_REPO env var triggers clone (using a local bare repo as the source)
fake_repo=$(mktemp -d)
git -C "$fake_repo" init --bare --quiet
CLAUDE_REPO="$fake_repo" ./install.sh >/dev/null
[[ -d "$HOME/.claude/.git" ]]
echo "  OK  CLAUDE_REPO env var triggers clone"

# Existing ~/.claude is left alone (no Skipped/Cloned message)
out=$(./install.sh 2>&1)
if grep -qE "(Skipped|Cloned) Claude" <<<"$out"; then
    echo "  FAIL  install.sh touched ~/.claude when already present"; exit 1
fi
echo "  OK  install.sh leaves existing ~/.claude alone"

# Clone failure (non-existent URL) -> WARNING, exits 0
rm -rf "$HOME/.claude"
out=$(CLAUDE_REPO="/tmp/does-not-exist-xyz" ./install.sh 2>&1)
grep -q "WARNING: clone failed" <<<"$out"
echo "  OK  install.sh warns on clone failure and exits cleanly"

seed=$(mktemp -d)
git -C "$seed" init --quiet
echo "repo version" > "$seed/settings.machine.json"
echo "repo readme" > "$seed/README.md"
git -C "$seed" add -A
git -C "$seed" -c user.name=test -c user.email=test@example.com commit --quiet -m seed
seeded_repo=$(mktemp -d)
git clone --quiet --bare "$seed" "$seeded_repo"

rm -rf "$HOME/.claude"
mkdir "$HOME/.claude"
echo "preexisting content" > "$HOME/.claude/notes.md"
echo "local version" > "$HOME/.claude/settings.machine.json"
out=$(CLAUDE_REPO="$seeded_repo" ./install.sh 2>&1)
grep -q "Attached Claude config to existing ~/.claude" <<<"$out"
[[ -d "$HOME/.claude/.git" ]]
[[ "$(cat "$HOME/.claude/notes.md")" == "preexisting content" ]]
[[ "$(cat "$HOME/.claude/settings.machine.json")" == "repo version" ]]
[[ "$(cat "$HOME/.claude/README.md")" == "repo readme" ]]
git -C "$HOME/.claude" rev-parse --abbrev-ref @{u} >/dev/null
if ls -d "$HOME"/.claude.backup-* >/dev/null 2>&1; then
    echo "  FAIL  existing ~/.claude was moved aside"; exit 1
fi
echo "  OK  existing ~/.claude attached in place (repo versions win, untracked files kept)"

rm -rf "$HOME/.claude"
mkdir "$HOME/.claude"
echo "preexisting content" > "$HOME/.claude/notes.md"
out=$(CLAUDE_REPO="/tmp/does-not-exist-xyz" ./install.sh 2>&1)
grep -q "WARNING: could not attach Claude config" <<<"$out"
[[ ! -e "$HOME/.claude/.git" && "$(cat "$HOME/.claude/notes.md")" == "preexisting content" ]]
echo "  OK  failed attach leaves ~/.claude as it was"

echo "==> ALL CHECKS PASSED"
'
