#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run]

Install the Fedora terminal packages, Oh My Zsh plugins, and tracked .zshrc.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

run() {
  if "$dry_run"; then
    printf ' +'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if [[ ! -r /etc/os-release ]]; then
  printf 'Cannot identify the operating system: /etc/os-release is unavailable.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != fedora ]]; then
  printf 'This installer currently supports Fedora only (detected: %s).\n' "${ID:-unknown}" >&2
  exit 1
fi

if ((EUID == 0)); then
  package_manager=(dnf)
else
  if ! command -v sudo >/dev/null 2>&1; then
    printf 'sudo is required to install Fedora packages.\n' >&2
    exit 1
  fi
  package_manager=(sudo dnf)
fi

packages=(
  zsh
  git
  curl
  fzf
  zoxide
  direnv
  bat
  eza
  less
  man-db
  openssh-clients
  PackageKit-command-not-found
  rsync
  wl-clipboard
  xclip
)

printf 'Installing Fedora terminal packages...\n'
run "${package_manager[@]}" install -y "${packages[@]}"

zsh_dir=${ZSH:-"$HOME/.oh-my-zsh"}
if [[ -d "$zsh_dir/.git" ]]; then
  printf 'Updating Oh My Zsh...\n'
  run git -C "$zsh_dir" pull --ff-only
elif [[ -e "$zsh_dir" ]]; then
  printf '%s exists but is not an Oh My Zsh Git checkout. Move it and retry.\n' "$zsh_dir" >&2
  exit 1
else
  printf 'Installing Oh My Zsh...\n'
  run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
fi

custom_plugins_dir="$zsh_dir/custom/plugins"
run mkdir -p "$custom_plugins_dir"

install_plugin() {
  local name=$1
  local repository=$2
  local destination="$custom_plugins_dir/$name"

  if [[ -d "$destination/.git" ]]; then
    printf 'Updating %s...\n' "$name"
    run git -C "$destination" pull --ff-only
  elif [[ -e "$destination" ]]; then
    printf '%s exists but is not a Git checkout. Move it and retry.\n' "$destination" >&2
    exit 1
  else
    printf 'Installing %s...\n' "$name"
    run git clone --depth=1 "$repository" "$destination"
  fi
}

install_plugin fzf-tab https://github.com/Aloxaf/fzf-tab.git
install_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
install_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git

target_zshrc="$HOME/.zshrc"
if [[ -e "$target_zshrc" ]] && ! cmp -s "$script_dir/.zshrc" "$target_zshrc"; then
  backup="$target_zshrc.backup.$(date +%Y%m%d%H%M%S)"
  printf 'Backing up %s to %s...\n' "$target_zshrc" "$backup"
  run cp -p "$target_zshrc" "$backup"
fi

printf 'Installing .zshrc...\n'
run install -m 0644 "$script_dir/.zshrc" "$target_zshrc"

printf '\nTerminal setup complete. Start a new Zsh session or run: exec zsh\n'
zsh_path=$(command -v zsh || printf '/usr/bin/zsh')
if [[ ${SHELL:-} != "$zsh_path" ]]; then
  printf 'To make Zsh your login shell, run: chsh -s %s\n' "$zsh_path"
fi
