# Validation / 验证范围

Date: 2026-09-23. One original NanoPi R2S (RK3328, ARM64, approximately 1 GB RAM),
one nominal 16 GB microSD. This is not a broad hardware compatibility certification.

## Original private build: physically tested

- Kali rolling 2026.3 userspace, vendor kernel 6.6.134+.
- Two physical boots; a marker file persisted across reboot.
- eth0 DHCP and SSH recovered; second NIC was detected as eth1.
- Persistent OverlayFS storage automatically grew to approximately 12 GiB.
- About 473 MiB of lz4 zram; no failed systemd units.
- DNS and HTTPS access to the Kali mirror worked.
- Idle memory approximately 155–188 MiB in the minimal setup.
- GPT verification, rootfs/userdata e2fsck, SSH configuration and sudo permissions
  passed; boot payloads matched the original prefix outside GPT metadata.

The private baseline used different login provisioning and a private SSH public
key. That image and device-specific logs are **not release assets**.

The baseline package inventory is [baseline-packages.tsv](baseline-packages.tsv).
It records the tested private build; it is not a lockfile for future builds.

## Pi on the same physical board

Node 24.21.0 (Linux ARM64), npm 11.19.0 and Pi 0.87.1 ran successfully. Pi connected
to a remote inference server and performed real `read` and `bash` calls, retrieving
a test marker and `uname -m`. One run took 16.05 seconds with about 146.1 MiB peak
process RSS. This measures that one task/backend, not throughput or a concurrency
limit. The public installer pins those versions; the example endpoint is generic.

## Public v0.1.0 code

- Shell syntax and ShellCheck static analysis.
- Tests reject wrong sector size, missing/extra partitions and wrong rootfs/boot
  offsets or sizes; compact layout preserves the tested rootfs offset.
- Public health-check script passed on the running board.
- Public rootfs configuration ran against an offline copy of the baseline on ARM64.
  A disposable test public key was provisioned; effective sshd configuration
  confirmed password/keyboard-interactive/root login disabled. Sudo configuration
  parsed successfully. Device mounts and the original sudo file mode were restored
  after the offline extraction, which did not preserve them.
- The public assembly script completed on that offline fixture: both ext4
  filesystems passed e2fsck, compact GPT passed sfdisk verification, boot payloads
  matched outside GPT metadata, and gzip integrity plus SHA-256 generation passed.
  This validates assembly, not a fresh public debootstrap run or physical boot.

The release check does not reflash the user's running board. Public first-boot
key-only login, arbitrary fresh vendor images, future rolling repository contents,
and other cards/boards require additional end-to-end validation. A full fresh
public debootstrap build is not claimed as hardware boot-tested.

## Constraints

- Vendor-specific nine-partition boot/OverlayFS design, not a generic Kali installer.
- Only the recorded 6.6.134+ kernel is accepted by the initial build script.
- The exact original factory image filename and kernel source commit are unknown.
- No vendor binaries or ready-to-flash image in this source release.
- Package versions depend on the live Kali rolling archive. The partition size is
  fixed; a future larger rootfs can exceed it and the build will fail.
- Slow microSD random writes were the main practical bottleneck during setup.
- Built-in Ethernet only was tested. Wi-Fi injection/monitor-mode capability,
  USB adapter drivers, routing performance and multiple concurrent agents were
  not evaluated.

中文：实机启动与 Pi 工具调用验证来自原始私有版本；公开版使用不同的登录配置，
不能把原始版本的启动结果直接等同于公开版已重新刷机验证。这里分别记录验证边界。
