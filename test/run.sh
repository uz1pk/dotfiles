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

echo "==> ALL CHECKS PASSED"
'
