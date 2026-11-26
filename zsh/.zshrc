export ZSH="$HOME/.oh-my-zsh"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

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
alias cat='bat'
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -la --icons=auto --git --group-directories-first'
alias lt='eza --tree --level=2 --icons=auto'
