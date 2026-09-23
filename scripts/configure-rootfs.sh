#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID == 0 && $# == 2 ]] || { echo 'Internal helper: ROOTFS PUBLIC_KEY' >&2; exit 2; }
R=$(realpath -- "$1")
KEY=$(realpath -- "$2")
[[ $R != / && -f $R/etc/os-release ]]
grep -q '^ID=kali' "$R/etc/os-release"
ssh-keygen -lf "$KEY" >/dev/null
printf 'kali-r2s\n' > "$R/etc/hostname"
printf '127.0.0.1 localhost\n127.0.1.1 kali-r2s\n::1 localhost ip6-localhost ip6-loopback\n' > "$R/etc/hosts"
printf '# Root and persistent overlay are mounted by the R2S vendor initramfs.\n' > "$R/etc/fstab"
printf 'en_US.UTF-8 UTF-8\n' > "$R/etc/locale.gen"
chroot "$R" locale-gen
printf 'LANG=en_US.UTF-8\n' > "$R/etc/default/locale"
ln -sf /usr/share/zoneinfo/Etc/UTC "$R/etc/localtime"
chroot "$R" useradd -m -s /bin/bash -u 1000 -G sudo,adm,dialout pi
printf 'pi:%s\n' "$(openssl rand -hex 32)" | chroot "$R" chpasswd
printf 'pi ALL=(ALL:ALL) NOPASSWD: ALL\n' > "$R/etc/sudoers.d/90-pi"
chmod 440 "$R/etc/sudoers.d/90-pi"
chroot "$R" visudo -cf /etc/sudoers.d/90-pi
chroot "$R" passwd -l root
mkdir -p "$R/home/pi/.ssh"
cp "$KEY" "$R/home/pi/.ssh/authorized_keys"
chmod 700 "$R/home/pi/.ssh"
chmod 600 "$R/home/pi/.ssh/authorized_keys"
chroot "$R" chown -R pi:pi /home/pi
mkdir -p "$R/etc/NetworkManager/system-connections" "$R/etc/NetworkManager/conf.d"
cat > "$R/etc/NetworkManager/conf.d/10-r2s.conf" <<'EOF'
[main]
no-auto-default=*
EOF
cat > "$R/etc/NetworkManager/system-connections/management.nmconnection" <<'EOF'
[connection]
id=management
type=ethernet
interface-name=eth0
autoconnect=true
[ethernet]
[ipv4]
method=auto
dhcp-client-id=mac
[ipv6]
method=auto
EOF
chmod 600 "$R/etc/NetworkManager/system-connections/management.nmconnection"
# Keep the management port kernel name; USB-port naming is checked after boot.
ln -sf /dev/null "$R/etc/systemd/network/99-default.link"
rm -f "$R/etc/resolv.conf"
ln -s /run/NetworkManager/resolv.conf "$R/etc/resolv.conf"
cat > "$R/etc/default/zramswap" <<'EOF'
ALGO=lz4
PERCENT=50
PRIORITY=100
EOF
mkdir -p "$R/etc/systemd/journald.conf.d"
printf '[Journal]\nStorage=volatile\nRuntimeMaxUse=32M\n' > "$R/etc/systemd/journald.conf.d/10-r2s.conf"
cat > "$R/etc/systemd/system/r2s-ssh-hostkeys.service" <<'EOF'
[Unit]
Description=Create SSH host keys on first boot
Before=ssh.service
[Service]
Type=oneshot
ExecStart=/usr/bin/ssh-keygen -A
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
mkdir -p "$R/etc/systemd/system/ssh.service.d"
printf '[Unit]\nRequires=r2s-ssh-hostkeys.service\nAfter=r2s-ssh-hostkeys.service\n' > "$R/etc/systemd/system/ssh.service.d/hostkeys.conf"
rm -f "$R/etc/ssh/ssh_host_"*
mkdir -p "$R/etc/ssh/sshd_config.d"
printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitEmptyPasswords no\nPermitRootLogin no\n' > "$R/etc/ssh/sshd_config.d/10-r2s.conf"
systemctl --root="$R" enable ssh NetworkManager systemd-timesyncd zramswap r2s-ssh-hostkeys.service
systemctl --root="$R" set-default multi-user.target
rm -f "$R/var/lib/dbus/machine-id"
ln -s /etc/machine-id "$R/var/lib/dbus/machine-id"
