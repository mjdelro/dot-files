#!/usr/bin/env bash

set -Eeuo pipefail

readonly DOTFILES_VERSION="1.0.0"

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
backup_stamp=$(date +%Y%m%d%H%M%S)

dry_run=false
skip_apps=false
skip_gnome=false

usage() {
  cat <<EOF
dot-files v${DOTFILES_VERSION} — Fedora Workstation & Terminal Environment Installer

Usage: ./install.sh [OPTIONS]

Installs and configures a reproducible Fedora work environment:
  - Zsh, Oh My Zsh, custom plugins (fzf-tab, autosuggestions, syntax-highlighting)
  - Starship prompt (bracketed-segments preset) + modern CLI tools (eza, bat, fzf, zoxide, direnv)
  - Ghostty terminal (via COPR) + Warm Coal / Warm Paper themes
  - Zed editor + settings & Warm Coal / Warm Paper theme
  - Global & GNOME fonts (Atkinson Hyperlegible Next, Charis, Intel One Mono, IntoneMono Nerd Font)
  - Fontconfig rules, GTK3/GTK4 Warm Coal CSS, GNOME Shell Warm-Coal theme, and GNOME gsettings

Options:
  --dry-run      Print planned actions without making any changes
  --skip-apps    Skip installing Ghostty and Zed binaries (still deploys configs)
  --skip-gnome   Skip GNOME Shell theme extension and gsettings configuration
  -v, --version  Show installer version
  -h, --help     Show this help message
EOF
}

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --skip-apps)
      skip_apps=true
      ;;
    --skip-gnome)
      skip_gnome=true
      ;;
    -v|--version)
      printf 'dot-files %s\n' "$DOTFILES_VERSION"
      exit 0
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

step() {
  printf '\n==> %s\n' "$1"
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

# ------------------------------------------------------------------------------
# 1. Fedora packages (CLI tools, fonts, GNOME user-theme extension)
# ------------------------------------------------------------------------------
packages=(
  # Shell & CLI tools
  zsh
  git
  curl
  tar
  xz
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
  fontconfig

  # Global & GNOME fonts
  atkinson-hyperlegible-next-fonts
  atkinson-hyperlegible-mono-fonts
  sil-charis-fonts
  intel-one-mono-fonts
  google-noto-sans-tagalog-fonts
)

if ! "$skip_gnome"; then
  packages+=(gnome-shell-extension-user-theme)
fi

step "Installing Fedora packages..."
run "${package_manager[@]}" install -y "${packages[@]}"

# ------------------------------------------------------------------------------
# 2. Ghostty (COPR) & Zed Editor
# ------------------------------------------------------------------------------
if ! "$skip_apps"; then
  step "Installing Ghostty (COPR: scottames/ghostty)..."
  run "${package_manager[@]}" copr enable -y scottames/ghostty
  run "${package_manager[@]}" install -y ghostty

  step "Installing Zed editor..."
  if command -v zed >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/zed" ]]; then
    printf 'Zed is already installed; skipping.\n'
  elif "$dry_run"; then
    printf ' + curl -fsSL https://zed.dev/install.sh | sh\n'
  else
    curl -fsSL https://zed.dev/install.sh | sh
  fi
fi

# ------------------------------------------------------------------------------
# 3. Starship prompt (pinned release with SHA-256 verification)
# ------------------------------------------------------------------------------
install_starship() {
  local version=1.27.0
  local target checksum

  if [[ -x "$HOME/.local/bin/starship" ]] && "$HOME/.local/bin/starship" --version 2>/dev/null | grep -q "starship $version"; then
    printf 'Starship %s is already installed; skipping.\n' "$version"
    return
  fi

  case "$(uname -m)" in
    x86_64)
      target=x86_64-unknown-linux-gnu
      checksum=3b94758850901717eb36aa1b53f8492c1322506ec6d41273bc6151e79ed8e4a1
      ;;
    aarch64)
      target=aarch64-unknown-linux-musl
      checksum=341f5cbf24699fa0b27ec88965ad25f862ea09e15d35a543fd6ffdff1d2aa00d
      ;;
    *)
      printf 'Starship is not configured for architecture: %s\n' "$(uname -m)" >&2
      exit 1
      ;;
  esac

  local archive_name="starship-$target.tar.gz"
  local url="https://github.com/starship/starship/releases/download/v$version/$archive_name"

  if "$dry_run"; then
    printf ' + download and verify %s\n' "$url"
    printf ' + install starship to %q\n' "$HOME/.local/bin/starship"
    return
  fi

  local archive binary
  archive=$(mktemp)
  binary=$(mktemp)
  trap 'rm -f -- "$archive" "$binary"' RETURN

  curl -fsSL "$url" -o "$archive"
  printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check --status
  tar -xOf "$archive" starship >"$binary"
  install -d "$HOME/.local/bin"
  install -m 0755 "$binary" "$HOME/.local/bin/starship"
}

step "Installing Starship prompt..."
install_starship

# ------------------------------------------------------------------------------
# 4. IntoneMono Nerd Font (patched Intel One Mono)
# ------------------------------------------------------------------------------
install_intone_mono_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/IntoneMono"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IntelOneMono.tar.xz"

  if [[ -d "$font_dir" ]] && compgen -G "$font_dir/*.ttf" >/dev/null 2>&1; then
    printf 'IntoneMono Nerd Font is already installed; skipping.\n'
    return
  fi

  if "$dry_run"; then
    printf ' + mkdir -p %q\n' "$font_dir"
    printf ' + download %s and extract to %q\n' "$url" "$font_dir"
    return
  fi

  local archive
  archive=$(mktemp)
  trap 'rm -f -- "$archive"' RETURN

  mkdir -p "$font_dir"
  curl -fsSL "$url" -o "$archive"
  tar -xf "$archive" -C "$font_dir"
}

step "Installing IntoneMono Nerd Font..."
install_intone_mono_nerd_font

# ------------------------------------------------------------------------------
# 5. Oh My Zsh & custom Zsh plugins
# ------------------------------------------------------------------------------
step "Installing / updating Oh My Zsh and plugins..."
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

# ------------------------------------------------------------------------------
# 6. Deploy configuration files (with timestamped backups on changes)
# ------------------------------------------------------------------------------
install_file() {
  local src=$1
  local dst=$2
  local dst_dir
  dst_dir=$(dirname -- "$dst")

  run mkdir -p "$dst_dir"

  if [[ -e "$dst" ]] && ! cmp -s "$src" "$dst"; then
    local backup="${dst}.backup.${backup_stamp}"
    printf 'Backing up %s -> %s\n' "$dst" "$backup"
    run cp -p "$dst" "$backup"
  fi

  run install -m 0644 "$src" "$dst"
}

step "Deploying Zsh & Starship configs..."
install_file "$script_dir/zsh/.zshrc" "$HOME/.zshrc"
install_file "$script_dir/config/starship.toml" "$HOME/.config/starship.toml"

step "Deploying Ghostty config & themes..."
install_file "$script_dir/config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
for theme_file in "$script_dir/config/ghostty/themes"/*; do
  install_file "$theme_file" "$HOME/.config/ghostty/themes/$(basename -- "$theme_file")"
done

step "Deploying Zed config & themes..."
install_file "$script_dir/config/zed/settings.json" "$HOME/.config/zed/settings.json"
for theme_file in "$script_dir/config/zed/themes"/*.json; do
  install_file "$theme_file" "$HOME/.config/zed/themes/$(basename -- "$theme_file")"
done

step "Deploying global fontconfig rules..."
for conf_file in "$script_dir/config/fontconfig/conf.d"/*.conf; do
  install_file "$conf_file" "$HOME/.config/fontconfig/conf.d/$(basename -- "$conf_file")"
done

step "Deploying GTK & GNOME Shell Warm-Coal theme files..."
install_file "$script_dir/config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
install_file "$script_dir/config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
install_file "$script_dir/themes/Warm-Coal/gnome-shell/gnome-shell.css" "$HOME/.local/share/themes/Warm-Coal/gnome-shell/gnome-shell.css"

step "Refreshing font cache..."
run fc-cache -f

# ------------------------------------------------------------------------------
# 7. Apply GNOME theme & font settings
# ------------------------------------------------------------------------------
apply_gsetting() {
  local schema=$1
  local key=$2
  local value=$3

  if "$dry_run"; then
    printf ' + gsettings set %q %q %q\n' "$schema" "$key" "$value"
    return
  fi

  if gsettings list-schemas 2>/dev/null | grep -qx "$schema"; then
    gsettings set "$schema" "$key" "$value"
  else
    printf 'Schema %s not available; skipping %s.\n' "$schema" "$key"
  fi
}

if ! "$skip_gnome"; then
  if command -v gsettings >/dev/null 2>&1; then
    step "Applying GNOME theme & typography settings..."
    apply_gsetting org.gnome.desktop.interface color-scheme 'prefer-dark'
    apply_gsetting org.gnome.desktop.interface accent-color 'green'
    apply_gsetting org.gnome.desktop.interface gtk-theme 'Adwaita'
    apply_gsetting org.gnome.desktop.interface icon-theme 'Adwaita'
    apply_gsetting org.gnome.desktop.interface cursor-theme 'Adwaita'

    apply_gsetting org.gnome.desktop.interface font-name 'Atkinson Hyperlegible Next 11'
    apply_gsetting org.gnome.desktop.interface document-font-name 'Charis 11'
    apply_gsetting org.gnome.desktop.interface monospace-font-name 'Intel One Mono 11'
    apply_gsetting org.gnome.desktop.interface font-antialiasing 'rgba'
    apply_gsetting org.gnome.desktop.interface font-hinting 'slight'

    apply_gsetting org.gnome.desktop.wm.preferences titlebar-font 'Atkinson Hyperlegible Next Bold 11'
    apply_gsetting org.gnome.desktop.wm.preferences titlebar-uses-system-font true
    apply_gsetting org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    if command -v gnome-extensions >/dev/null 2>&1; then
      if "$dry_run"; then
        printf ' + gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com\n'
      else
        gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
      fi
    fi
    apply_gsetting org.gnome.shell.extensions.user-theme name 'Warm-Coal'
  else
    printf '\ngsettings not found; skipping GNOME desktop settings.\n'
  fi
fi

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------
printf '\ndot-files v%s setup complete!\n' "$DOTFILES_VERSION"
printf '  - Start a new Zsh session or run: exec zsh\n'
zsh_path=$(command -v zsh || printf '/usr/bin/zsh')
if [[ ${SHELL:-} != "$zsh_path" ]]; then
  printf '  - Make Zsh your login shell:      chsh -s %s\n' "$zsh_path"
fi
if ! "$skip_gnome"; then
  printf '  - Log out and back in if the GNOME Shell Warm-Coal theme does not apply immediately.\n'
fi
