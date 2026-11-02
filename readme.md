# Dot files

Personal Fedora terminal configuration and an archived Raspberry Pi network configuration.

## Terminal setup

The installer configures the current user with:

- Zsh and Oh My Zsh with the Starship prompt
- Fedora packages for Git, `fzf`, `zoxide`, `direnv`, `bat`, `eza`, man pages, SSH, `rsync`, command lookup, and clipboard integration
- `fzf-tab`, `zsh-autosuggestions`, and `zsh-syntax-highlighting`
- Oh My Zsh's bundled Git, Fedora, systemd, Docker, rsync, SSH agent, navigation, and convenience plugins
- `cat` mapped to `bat` and `ls` mapped to `eza`

Starship is installed from its official release archive into `~/.local/bin`. The installer pins a tested release and verifies its SHA-256 checksum before replacing the binary.

Review the planned commands:

```bash
./install.sh --dry-run
```

Install or update the setup:

```bash
./install.sh
```

The script is idempotent. It updates existing Git checkouts with fast-forward-only pulls and creates a timestamped backup before replacing a different `~/.zshrc`. Fedora package installation uses `sudo` and may prompt for a password.

The Docker shell plugins expect a Docker CLI, and the `codium` alias expects VSCodium's Flatpak package. The installer does not install either application. Use `command cat` or `command ls` to bypass the modern aliases.

## `dhcpcd.conf`

This archived file assigns `eth0` the static address `192.168.1.234/24`, uses `192.168.1.1` as the router, and points DNS at `127.0.0.1`.

Do not copy it over `/etc/dhcpcd.conf` unchanged. Confirm the interface name, subnet, router address, and local DNS service first. A wrong value can disconnect the machine from the network.

Many current Linux distributions use NetworkManager or systemd-networkd instead of `dhcpcd`.

## License

See [LICENSE](LICENSE).
