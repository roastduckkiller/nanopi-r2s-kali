#!/usr/bin/env bash
set -uo pipefail
failed=0
check() { if "$@"; then printf 'PASS: %s\n' "$*"; else printf 'FAIL: %s\n' "$*"; failed=1; fi; }
check grep -q '^ID=kali' /etc/os-release
check test "$(uname -m)" = aarch64
check test "$(uname -r)" = 6.6.134+
check systemctl is-active --quiet ssh NetworkManager zramswap
check test -r /sys/class/net/eth0/address
# Hardware naming of the USB Ethernet port can differ between udev versions.
check bash -c 'ip -o link show | grep -Eq "(eth1|enx[[:xdigit:]]+)"'
check bash -c 'findmnt -n -o FSTYPE / | grep -qx overlay'
check bash -c 'swapon --noheadings --show=NAME | grep -q /dev/zram'
check nmap --version
check python3 --version
ip -br address
free -h
df -h /
systemctl --failed --no-pager
failed_units=$(systemctl --failed --no-legend --plain) || failed=1
check test -z "$failed_units"
exit "$failed"
