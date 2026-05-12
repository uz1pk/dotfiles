# ----------------------------
# Oh my ZSH config
# ----------------------------

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto      # update automatically without asking

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting z)

source $ZSH/oh-my-zsh.sh

# ----------------------------
# NVM Setup
# ----------------------------

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ----------------------------
# Aliases
# ----------------------------

alias gw="./gradlew"
branch() { git checkout -b "uz/$1"; }
alias python='python3'
alias broom="git add . && git commit -m ':broom:' && git push"
alias glist="git branch -l"
gdl() { git branch -D "$1"; }

# ----------------------------
# Java exports (if I need to change versions)
# ----------------------------

#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-15.jdk/Contents/Home
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home

# ----------------------------
# Rust
# ----------------------------

# export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc

# ----------------------------
# Idea commands
# ----------------------------

export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# ----------------------------
# Pyenv and Pipx
# ----------------------------

# Created by `pipx` on 2025-03-05 22:27:17
export PATH="$PATH:$HOME/.local/bin"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ----------------------------
# Claude Code settings
# ----------------------------

export DISABLE_TELEMETRY=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export CLAUDE_CODE_SUBAGENT_MODEL=claude-opus-4-6
export NODE_OPTIONS="--max-old-space-size=8192"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

# ----------------------------
# Machine-specific overrides (not tracked)
# ----------------------------

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
