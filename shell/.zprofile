# Welcome message with current user
echo "Good morning ${USER:-$(whoami)}!"

# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# Autojump configuration for smart directory navigation
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# NVM (Node Version Manager) setup
export NVM_DIR="${HOME}/.nvm"
[ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh
[ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm


# Additional PATH entries (legacy tools)
export PATH="$PATH:/usr/local/bin"

# Kubernetes aliases for faster workflow
alias k="kubectl"
alias kg="kubectl get"
alias kgp="kubectl get pods"
alias kgd="kubectl get deployments"
alias kgs="kubectl get services"
alias kga="kubectl get all"
alias kd="kubectl describe"
alias kaf="kubectl apply -f"
alias kdf="kubectl delete -f"
