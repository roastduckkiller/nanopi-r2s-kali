#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# == 1 ]] || { echo 'Internal helper: BUILD_DIRECTORY' >&2; exit 2; }
B=$(realpath -- "$1")
R=$B/rootfs
I=$B/nanopi-r2s-kali.img
[[ -d $R && -f $B/compact.sfdisk && -f $B/boot-prefix.bin ]]
[[ ! -e $I && ! -e $I.gz ]] || { echo 'Output image already exists' >&2; exit 1; }
if findmnt -rn -o TARGET | awk -v root="$R" '$0 == root || index($0,root"/")==1 {found=1} END {exit !found}'; then
 echo 'Unmount rootfs before assembly' >&2; exit 1
fi
[[ $(stat -c %s "$B/boot-prefix.bin") == 134217728 ]]
truncate -s $((4456448 * 512)) "$B/rootfs.ext4"
mkfs.ext4 -F -L rootfs -d "$R" "$B/rootfs.ext4"
e2fsck -fn "$B/rootfs.ext4"
truncate -s $((524255 * 512)) "$B/userdata.ext4"
mkfs.ext4 -F -L userdata -m 1 "$B/userdata.ext4"
e2fsck -fn "$B/userdata.ext4"
truncate -s $((5242880 * 512)) "$I"
dd if="$B/boot-prefix.bin" of="$I" bs=1M conv=notrunc status=none
dd if="$B/rootfs.ext4" of="$I" bs=1M seek=128 conv=sparse,notrunc status=none
dd if="$B/userdata.ext4" of="$I" bs=1M seek=2304 conv=sparse,notrunc status=none
sfdisk --force --wipe never --wipe-partitions never "$I" < "$B/compact.sfdisk"
sfdisk --verify "$I"
cmp -i 17408 -n $((128 * 1024 * 1024 - 17408)) "$I" "$B/boot-prefix.bin"
gzip -1 -c "$I" > "$I.gz"
gzip -t "$I.gz"
(cd "$B" && sha256sum nanopi-r2s-kali.img.gz > SHA256SUMS)
