echo "Hello!"
eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
  export NVM_DIR=/Users/yvan/.nvm
  [ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh  # This loads nvm
  [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm  # This loads nvm bash_completion


# Added by Toolbox App
export PATH="$PATH:/usr/local/bin"

