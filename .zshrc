export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"

ZSH_THEME=""

plugins=(
  # Core
  git
  aliases
  sudo

  # Fedora / Linux
  dnf
  systemd

  # Development / servers
  docker
  docker-compose
  rsync
  ssh-agent

  # Convenience
  extract
  colored-man-pages
  command-not-found
  copybuffer
  copyfile
  copypath

  # Navigation / fuzzy search
  fzf
  zoxide
  direnv

  # Interactive shell
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
eval "$(starship init zsh)"

# Flatpak VSCodium
alias codium='flatpak run com.vscodium.codium'

# Modern replacements; use `command cat` or `command ls` for the originals.
alias cat='bat'
alias ls='eza'
