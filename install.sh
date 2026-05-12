#!/usr/bin/env bash
# Bootstrap: install stow if needed, symlink every package into $HOME.
set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! command -v stow &>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command -v brew &>/dev/null || { echo "Homebrew required: https://brew.sh"; exit 1; }
        brew install stow
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y stow
    else
        echo "Install GNU Stow manually for your platform, then re-run."; exit 1
    fi
fi

cd "$DOTFILES_DIR"

for pkg in */; do
    pkg="${pkg%/}"
    case "$pkg" in
        .git|test) continue ;;
    esac
    echo "Stowing $pkg..."
    stow -R "$pkg"
done

for local_file in .zshrc.local .zshenv.local .zprofile.local; do
    if [[ ! -f "$HOME/$local_file" ]]; then
        touch "$HOME/$local_file"
        chmod 600 "$HOME/$local_file"
        echo "Created empty ~/$local_file (mode 600)."
    fi
done

echo "Done. Open a new shell."
