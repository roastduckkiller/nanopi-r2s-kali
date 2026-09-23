# NanoPi R2S Headless Kali

[中文说明](README.zh-CN.md) · [Pi agent setup](docs/pi-agent.md) · [Validation](docs/validation.md)

Build an unofficial **Kali Linux® ARM64 command-line system for the NanoPi R2S**,
retaining the board's working FriendlyELEC boot chain and kernel. Turn a 1 GB R2S
into a small SSH-accessible lab node, with an optional Pi coding agent connected
to a remote LLM server.

**v0.1.0 is an experimental source/build-tool release, not a downloadable SD image.**
The original private build booted successfully on real hardware. The public recipe
changes login provisioning and removes private settings; its validation status is
tracked separately in [the test report](docs/validation.md).

## Supported starting point

- Original NanoPi R2S, ARM64, vendor kernel **6.6.134+**.
- Already running a compatible vendor nine-partition GPT layout: p8 rootfs at
  sector 262144, p9 userdata at 4718592, vendor initramfs managing OverlayFS.
- Native ARM64 build on that board, Debian/Ubuntu/Kali userspace with apt.
- Internet access, a 16 GB or larger card, and at least **8 GiB free build space**.
- A separate machine/card reader for flashing, and your own SSH key pair.

R2S Plus, OpenWrt layouts, mainline single-root layouts, other kernels and x86
cross-builds are not supported by this initial recipe. The script stops on
unrecognized layout/kernel. Obtain a suitable starting system from the
[FriendlyELEC R2S documentation](https://wiki.friendlyelec.com/wiki/index.php/NanoPi_R2S).
The exact original factory image filename was not recorded; kernel and layout
checks are necessary compatibility checks, not a guarantee for every vendor image.

## Build

Run on the R2S. Building creates files only; it never flashes the running card.
Small SD-card writes are slow: allow substantial time and use `tmux`.

```sh
sudo apt-get update
sudo apt-get install -y debootstrap fdisk e2fsprogs rsync curl gnupg \
  openssh-client openssl python3 util-linux gzip git tmux
# Clone here, or unpack the release archive.
git clone https://github.com/roastduckkiller/nanopi-r2s-kali.git
cd nanopi-r2s-kali
# Copy ONLY your SSH public key to ~/r2s-login.pub beforehand.
sudo ./scripts/build.sh /var/tmp/r2s-kali-build "$HOME/r2s-login.pub"
# Optional faster mirror: append https://mirrors.ustc.edu.cn/kali
```

The output directory must be new. Outputs include `nanopi-r2s-kali.img.gz`,
`SHA256SUMS`, and `packages.tsv`. The raw image is 2.5 GiB; the tested private
baseline compressed to about 251 MiB. Kali rolling packages are downloaded at
build time, so future output is **not bit-for-bit reproducible**.

The build embeds the explicitly supplied public key. No existing user's home,
SSH credentials or agent configuration is copied. Vendor boot partitions are
copied from your board, so **treat generated images as personal artifacts**;
the source release itself contains no board dump or credentials.

## Flash and first login

1. Copy the compressed image and checksum file to your workstation and verify
   with `sha256sum -c SHA256SUMS` (macOS: `shasum -a 256 -c SHA256SUMS`).
2. Shut down the R2S. Flash its card with a tool that supports `.img.gz`, such as
   balenaEtcher, and enable verification. **Flashing erases the selected card.**
   Keep a backup or spare known-working card for recovery.
3. Insert the card, connect the original management Ethernet port and power on.
   Allow a few minutes for the vendor initramfs to expand the persistent partition.
4. Find the DHCP lease, then `ssh -i /path/to/your/private-key pi@BOARD_IP`.

Public recipe: **SSH key login only, no shared password**, root SSH disabled.
User `pi` has passwordless sudo; possession of the selected key grants admin
access. SSH host keys and machine identity are generated on first boot. Hostname
is `kali-r2s`, timezone UTC. Keep your private key on your workstation.

The management port is `eth0` with DHCP. The second NIC has no automatic profile,
bridge, NAT or forwarding configuration. Check its actual name with `ip -br link`.

## What's included

Nmap, tcpdump, netcat, socat, DNS tools, traceroute, mtr, ethtool, curl, wget, Git,
Python/pip/venv, jq, tmux, SSH and basic storage tools. No desktop, no full Kali
metapackage. Zram uses 50% of RAM with lz4; volatile journals are capped at 32 MiB.
The kernel is supplied by the vendor, not replaced with a generic Kali kernel.

For Pi: follow [docs/pi-agent.md](docs/pi-agent.md). Inference runs on your server;
R2S runs the agent and local tools. Node/Pi are optional post-flash installations.

## Verification and recovery

Run `bash scripts/healthcheck.sh` on the board, then create a test file in your
home, reboot and confirm it persists. A passing health check does not substitute
for this reboot test. [Validation and known limitations](docs/validation.md)
include observed RAM use and Pi tool-call results.

If SSH does not return, check DHCP, the Ethernet port and the key used at build
time. A 3.3 V serial console can help diagnose boot issues. Reflash your saved
vendor image to recover. Do not write to a guessed `/dev/diskN` or `/dev/sdX`.

## Development and licensing

```sh
python3 -m unittest discover -s tests -v
for script in scripts/*.sh; do bash -n "$script"; done
```

Repository code is MIT licensed. Kali packages, vendor kernel/firmware/bootloader,
Node.js and Pi retain their own licenses. This release distributes our source
recipe, not those binaries. See [THIRD_PARTY.md](THIRD_PARTY.md). This is an
independent community project, not an official Kali/OffSec or FriendlyELEC image.
Use it for systems you own or are authorized to assess.
