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

if [[ ! -d "$HOME/.claude/.git" ]]; then
    echo
    if [[ -t 0 ]]; then
        read -rp "Enter Claude config repo URL (empty to skip): " claude_repo
    else
        claude_repo="${CLAUDE_REPO:-}"
    fi
    if [[ -n "$claude_repo" ]]; then
        if [[ -d "$HOME/.claude" && -n "$(ls -A "$HOME/.claude" 2>/dev/null)" ]]; then
            backup="$HOME/.claude.backup-$(date +%Y%m%d-%H%M%S)"
            mv "$HOME/.claude" "$backup"
            echo "  Moved existing untracked ~/.claude to $backup"
        fi
        if git clone "$claude_repo" "$HOME/.claude"; then
            echo "  Cloned Claude config to ~/.claude"
        else
            echo "  WARNING: clone failed. ~/.claude was not set up."
        fi
    else
        echo "  Skipped Claude config clone."
    fi
fi

if ! command -v claude &>/dev/null; then
    echo
    echo "WARNING: 'claude' CLI not found in PATH."
    echo "  Install Claude Code: https://docs.anthropic.com/en/docs/claude-code/setup"
fi

echo "Done. Open a new shell."
