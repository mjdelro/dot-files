<p align="center">
  <img src="assets/icon.svg" alt="Dot Files Icon" width="104" height="104" />
</p>

<h1 align="center">Dot Files</h1>

<p align="center">Reproducible Fedora Workstation environment — Zsh, Starship, Ghostty, Zed, Warm Coal / Warm Paper theme, and typography.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Release-v1.0.0-347a45?style=flat-square" alt="Release v1.0.0" />
  <img src="https://img.shields.io/badge/Fedora-Workstation-51A2DA?style=flat-square&logo=fedora&logoColor=white" alt="Fedora Workstation" />
  <img src="https://img.shields.io/badge/Shell-Zsh%20%2B%20Starship-34d399?style=flat-square&logo=gnubash&logoColor=black" alt="Zsh + Starship" />
  <img src="https://img.shields.io/github/license/mjdelro/dot-files?style=flat-square&color=64748b" alt="License" />
</p>

---

## What's Included

### Shell & Prompt
- **Zsh + Oh My Zsh** ([`zsh/.zshrc`](zsh/.zshrc)) with bundled plugins (`git`, `aliases`, `sudo`, `dnf`, `systemd`, `docker`, `docker-compose`, `rsync`, `ssh-agent`, `extract`, `colored-man-pages`, `command-not-found`, `copybuffer`, `copyfile`, `copypath`, `fzf`, `zoxide`, `direnv`)
- **Custom Zsh plugins**: `fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- **Starship prompt** (`v1.27.0`, SHA-256 verified) with the `bracketed-segments` preset ([`config/starship.toml`](config/starship.toml))
- **Modern CLI replacements & aliases**: `bat` (`cat`), `eza` (`ls`, `ll`, `lt` with icons and `--group-directories-first`), `fzf`, `zoxide`, `direnv`, and Flatpak VSCodium (`codium`)

### Terminal & Editor
- **Ghostty** (via Fedora COPR `scottames/ghostty`) with [`config/ghostty/config.ghostty`](config/ghostty/config.ghostty) using `IntoneMono Nerd Font` and automatic dark/light switching between `Warm Coal` and `Warm Paper` ([`config/ghostty/themes/`](config/ghostty/themes/))
- **Zed** (via official installer) with [`config/zed/settings.json`](config/zed/settings.json) and the custom `Warm Coal` / `Warm Paper` theme ([`config/zed/themes/warm-coal-paper.json`](config/zed/themes/warm-coal-paper.json))

### GNOME Theme & Typography
- **Warm Coal / Warm Paper GNOME theme**:
  - GTK4 / libadwaita dark & light CSS ([`config/gtk-4.0/gtk.css`](config/gtk-4.0/gtk.css))
  - GTK3 dark CSS ([`config/gtk-3.0/gtk.css`](config/gtk-3.0/gtk.css))
  - GNOME Shell user theme ([`themes/Warm-Coal/gnome-shell/gnome-shell.css`](themes/Warm-Coal/gnome-shell/gnome-shell.css)) + `gnome-shell-extension-user-theme`
  - GNOME `gsettings` for dark color scheme, green accent, window buttons (`minimize,maximize,close`), and typography
- **Fonts & Fontconfig**:
  - Fedora packages: `Atkinson Hyperlegible Next`, `Atkinson Hyperlegible Mono`, `Charis`, `Intel One Mono`, `Noto Sans Tagalog`
  - Nerd Font: `IntoneMono Nerd Font` (patched Intel One Mono from Nerd Fonts releases)
  - Global fontconfig stack ([`config/fontconfig/conf.d/`](config/fontconfig/conf.d/))

---

## Fresh Fedora Install

Clone the repository and run the installer:

```bash
git clone https://github.com/mjdelro/dot-files.git
cd dot-files
./install.sh
```

### Options

```bash
./install.sh --dry-run      # Preview all actions without changing the system
./install.sh --skip-apps    # Skip installing Ghostty and Zed binaries (still deploys configs)
./install.sh --skip-gnome   # Skip GNOME user-theme extension and gsettings (useful for headless/servers)
./install.sh --version      # Show installer version
```

The installer is **idempotent**:
- Existing Oh My Zsh and plugin checkouts are updated with `git pull --ff-only`.
- Any existing config file that differs from the repo is backed up to `<file>.backup.<timestamp>` before being replaced.
- Already-installed Zed, Starship `1.27.0`, and `IntoneMono Nerd Font` binaries/fonts are skipped automatically.

---

## Repository Structure

```text
dot-files/
├── assets/
│   └── icon.svg
├── config/
│   ├── fontconfig/conf.d/
│   ├── ghostty/
│   │   ├── config.ghostty
│   │   └── themes/
│   ├── gtk-3.0/gtk.css
│   ├── gtk-4.0/gtk.css
│   ├── starship.toml
│   └── zed/
│       ├── settings.json
│       └── themes/warm-coal-paper.json
├── themes/
│   └── Warm-Coal/gnome-shell/gnome-shell.css
├── zsh/
│   └── .zshrc
├── install.sh
├── LICENSE
└── README.md
```

## License

See [LICENSE](LICENSE).
