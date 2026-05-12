#!/usr/bin/env bash
# Run install.sh in a clean Ubuntu container, assert symlinks and bootstrap landed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker build -q -t dotfiles-test "$REPO_ROOT/test" >/dev/null

docker run --rm -v "$REPO_ROOT:/dotfiles-src:ro" dotfiles-test bash -c '
set -euo pipefail

cp -r /dotfiles-src "$HOME/dotfiles"
cd "$HOME/dotfiles"
./install.sh

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

for f in .zshrc.local .zshenv.local .zprofile.local; do echo MARKER > "$HOME/$f"; done
./install.sh >/dev/null
for f in .zshrc.local .zshenv.local .zprofile.local; do
    [[ "$(cat "$HOME/$f")" == MARKER ]]
    echo "  OK  ~/$f preserved on rerun"
done

echo "==> ALL CHECKS PASSED"
'
