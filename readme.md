# Configuration files

This repository currently contains one Raspberry Pi network configuration from an older home-network setup.

## `dhcpcd.conf`

The file assigns `eth0` the static address `192.168.1.234/24`, uses `192.168.1.1` as the router, and points DNS at `127.0.0.1`.

Do not copy it over `/etc/dhcpcd.conf` unchanged. Confirm the interface name, subnet, router address, and local DNS service first. A wrong value can disconnect the machine from the network.

To use it as a reference:

```bash
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup
sudoedit /etc/dhcpcd.conf
```

Apply only the settings that match the target system. Many current Linux distributions use NetworkManager, netplan, or systemd-networkd instead of `dhcpcd`.

## License

See [LICENSE](LICENSE).
