# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# Autojump configuration for smart directory navigation
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# NVM (Node Version Manager)
export NVM_DIR="${HOME}/.nvm"
[ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh
[ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
