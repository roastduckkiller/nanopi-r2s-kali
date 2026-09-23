#!/usr/bin/env bash
# Build in files on an existing compatible R2S. Never flash a device.
set -Eeuo pipefail
export LC_ALL=C DEBIAN_FRONTEND=noninteractive
S=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
usage() { echo "Usage: sudo $0 NEW_OUTPUT_DIRECTORY SSH_PUBLIC_KEY [KALI_MIRROR]"; }
if [[ ${1:-} == --help ]]; then usage; exit 0; fi
[[ $# -ge 2 && $# -le 3 ]] || { usage >&2; exit 2; }
[[ $EUID == 0 && $(uname -m) == aarch64 ]] || { echo 'Run as root on native ARM64 Linux' >&2; exit 1; }
for cmd in debootstrap sfdisk mkfs.ext4 e2fsck python3 rsync curl gpg ssh-keygen chroot openssl; do
 command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
if [[ ! -f /proc/device-tree/model ]] || ! grep -aq 'NanoPi R2S' /proc/device-tree/model; then
 echo 'Requires a NanoPi R2S' >&2; exit 1
fi
if grep -aq 'Plus' /proc/device-tree/model; then echo 'R2S Plus is not validated' >&2; exit 1; fi
[[ $(uname -r) == 6.6.134+ ]] || { echo 'This release is scoped to the tested vendor kernel 6.6.134+' >&2; exit 1; }
grep -q 'root=/dev/mmcblk0p8' /proc/cmdline
grep -q 'data=/dev/mmcblk0p9' /proc/cmdline
[[ -b /dev/mmcblk0 && -b /dev/mmcblk0p9 ]]
KEY=$(realpath -- "$2")
[[ -f $KEY ]] && ssh-keygen -lf "$KEY" >/dev/null
[[ $(wc -l < "$KEY") -le 1 ]] || { echo 'Supply exactly one public key' >&2; exit 1; }
grep -Eq '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)) ' "$KEY"
B=$(realpath -m -- "$1")
[[ ! -e $B && $B != / ]] || { echo 'Output directory must not already exist' >&2; exit 1; }
MIRROR=${3:-https://http.kali.org/kali}
[[ $MIRROR == https://* && $MIRROR != *[$' \t\n']* ]] || { echo 'Use an HTTPS mirror URL without whitespace' >&2; exit 1; }
umask 077
mkdir -p "$B"
[[ $(df -Pk "$B" | awk 'NR==2 {print $4}') -ge 8388608 ]] || { echo 'At least 8 GiB free build space required' >&2; exit 1; }
sfdisk --json /dev/mmcblk0 > "$B/vendor-layout.json"
python3 "$S/layout.py" < "$B/vendor-layout.json" > "$B/compact.sfdisk"
# Only read boot payloads; nothing writes to /dev/mmcblk0.
dd if=/dev/mmcblk0 of="$B/boot-prefix.bin" bs=1M count=128 status=progress
R=$B/rootfs
cleanup() {
 for target in "$R/proc" "$R/dev/pts" "$R/dev"; do
  if mountpoint -q "$target"; then umount "$target" || true; fi
 done
}
trap cleanup EXIT
curl --fail --location --retry 3 https://archive.kali.org/archive-keyring.gpg -o "$B/kali-archive-keyring.gpg"
gpg --batch --show-keys --with-colons "$B/kali-archive-keyring.gpg" > "$B/key-info.txt"
grep -q '^fpr:::::::::827C8569F2518CC677FECA1AED65462EC8D5E4C5:' "$B/key-info.txt"
debootstrap --arch=arm64 --variant=minbase --include=ca-certificates,kali-archive-keyring \
 --keyring="$B/kali-archive-keyring.gpg" kali-rolling "$R" "$MIRROR" /usr/share/debootstrap/scripts/sid
printf 'deb %s kali-rolling main contrib non-free non-free-firmware\n' "$MIRROR" > "$R/etc/apt/sources.list"
printf '#!/bin/sh\nexit 101\n' > "$R/usr/sbin/policy-rc.d"
chmod 755 "$R/usr/sbin/policy-rc.d"
cp -L /etc/resolv.conf "$R/etc/resolv.conf"
mount --bind /dev "$R/dev"
mount --make-slave "$R/dev"
mount -t devpts devpts "$R/dev/pts"
mount -t proc proc "$R/proc"
chroot "$R" apt-get update
chroot "$R" apt-get install -y --no-install-recommends \
 systemd-sysv udev dbus network-manager openssh-server sudo locales \
 kali-defaults kali-archive-keyring ca-certificates systemd-timesyncd \
 nmap tcpdump netcat-openbsd socat dnsutils iproute2 iputils-ping \
 traceroute mtr-tiny ethtool curl wget git python3 python3-venv python3-pip \
 jq tmux less vim-tiny procps psmisc kmod e2fsprogs parted zram-tools
mkdir -p "$R/usr/lib/modules" "$R/usr/lib/firmware"
rsync -a /usr/lib/modules/6.6.134+ "$R/usr/lib/modules/"
rsync -a /usr/lib/firmware/ "$R/usr/lib/firmware/"
"$S/configure-rootfs.sh" "$R" "$KEY"
chroot "$R" depmod -a 6.6.134+
chroot "$R" apt-get clean
rm -f "$R/usr/sbin/policy-rc.d"
rm -rf "$R/var/lib/apt/lists/"*
# Avoid carrying build logs, generated identities, histories or resolver state.
find "$R/var/log" -type f -exec truncate -s 0 {} +
rm -f "$R/var/lib/systemd/random-seed" "$R/root/.bash_history"
truncate -s 0 "$R/etc/machine-id"
chroot "$R" dpkg-query -W > "$B/packages.tsv"
chroot "$R" dpkg --audit > "$B/dpkg-audit.txt"
[[ ! -s $B/dpkg-audit.txt ]]
mkdir -p "$R/run/sshd"
chroot "$R" ssh-keygen -A
chroot "$R" /usr/sbin/sshd -t
rm -f "$R/etc/ssh/ssh_host_"*
cleanup
trap - EXIT
"$S/assemble.sh" "$B"
echo "Build complete: $B/nanopi-r2s-kali.img.gz (contains your chosen public key)"
