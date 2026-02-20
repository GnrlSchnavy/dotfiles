# Welcome message with current user
HOUR=$(date +%H)
if   (( HOUR < 12 )); then GREETING="Good morning"
elif (( HOUR < 18 )); then GREETING="Good afternoon"
else GREETING="Good evening"; fi
echo "$GREETING ${USER:-$(whoami)}!"
unset HOUR GREETING

# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# Autojump configuration for smart directory navigation
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# NVM (Node Version Manager) - lazy-loaded for faster shell startup
export NVM_DIR="${HOME}/.nvm"
lazy_load_nvm() {
  unset -f nvm node npm npx
  [ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh
  [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm
}
nvm() { lazy_load_nvm && nvm "$@"; }
node() { lazy_load_nvm && node "$@"; }
npm() { lazy_load_nvm && npm "$@"; }
npx() { lazy_load_nvm && npx "$@"; }
