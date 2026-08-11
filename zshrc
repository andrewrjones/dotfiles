export PATH=$HOME/bin:/usr/local/bin:$PATH

export EDITOR='vim'

# Path to your oh-my-zsh installation.
export ZSH="/Users/$USER/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  macos
)

source $ZSH/oh-my-zsh.sh

# Replace cat with bat
alias cat='bat'

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /Users/andrewjones/bin/terraform terraform

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="${HOME}/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

if [ -f "${HOME}/.local/bin/env" ]; then . "$HOME/.local/bin/env"; fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "/Users/${USER}/google-cloud-sdk/path.zsh.inc" ]; then . "/Users/${USER}/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "/Users/${USER}/google-cloud-sdk/completion.zsh.inc" ]; then . "/Users/${USER}/google-cloud-sdk/completion.zsh.inc"; fi

# Worktree manager
# from https://gist.github.com/mathd/5ccfe70edc70c129828fadb9f54c7f5e
export W_PROJECTS_DIR="$HOME/work"
export W_WORKTREES_DIR="$HOME/work/worktrees"
source $HOME/.dotfiles/worktree-manager/worktree-manager.zsh


export SDKMAN_DIR="/opt/homebrew/opt/sdkman-cli/libexec"
sdk() {
  unset -f sdk
  [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
  sdk "$@"
}
source $HOME/.dotfiles/worktree-manager/worktree-manager.zsh

export PATH=$HOME/flutter/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# Tinybird
export TB_CLI_TELEMETRY_OPTOUT=true

# Github Copilot
export COPILOT_ALLOW_ALL=true

eval "$(mise activate zsh)"
# Automatically load dotenv files
export MISE_ENV_FILE=.env

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

# --- Project terminal background ---
# Sets the terminal background from the current git repo's colour.
# Colour comes from `project-color` (single source of truth on PATH).
_project_bg() {
  local color
  if color=$(project-color 2>/dev/null); then
    printf '\e]11;%s\e\\' "$color"
  else
    printf '\e]111\e\\'
  fi
}
# precmd (not chpwd) so the first prompt after a cmux session restore paints,
# and any later theme clobber self-heals on the next prompt.
precmd_functions+=(_project_bg)

# Claude
alias pcl='pbpaste >> CLAUDE.local.md'
export PATH="/opt/homebrew/bin:$PATH"
