# NanoPi R2S 无桌面 Kali 实验节点

[English](README.md) · [Pi 配置](docs/pi-agent.md) · [验证记录](docs/validation.md)

把约 1 GB 内存的 NanoPi R2S 变成 SSH 管理的 Kali Linux® ARM64 实验节点。
保留厂商启动链、内核和驱动，更换 Kali 用户空间；可选安装 Pi agent，连接远程模型服务器。

**v0.1.0 发布的是实验性源码构建包，不是可直接烧录的镜像。**
原始私有版本已经实机启动并验证重启持久化。公开配方改为使用构建者自己的 SSH 公钥，
去掉个人网络和模型配置；公开配方的验证范围请看[测试报告](docs/validation.md)。

## 适用范围

仅限原版 NanoPi R2S、ARM64、厂商内核 `6.6.134+`，以及兼容的九分区 GPT：
第 8 分区为 rootfs，第 9 分区为 userdata，厂商 initramfs 使用 OverlayFS 并自动扩容。
不是 R2S Plus / OpenWrt / 任意 ARM 板通用刷机工具。原始厂商镜像的完整文件名未记录，
因此仅通过内核与分区检查，不能保证所有厂商镜像都适用。

在该 R2S 上构建，要求至少 8 GiB 空闲空间、联网，以及另外一台电脑和读卡器用于刷卡。
推荐 16 GB 以上 microSD；小文件写入慢会明显延长构建时间，建议用 `tmux`。

## 构建与启动

```sh
sudo apt-get update
sudo apt-get install -y debootstrap fdisk e2fsprogs rsync curl gnupg \
  openssh-client openssl python3 util-linux gzip git tmux
git clone https://github.com/roastduckkiller/nanopi-r2s-kali.git
cd nanopi-r2s-kali
# 先从电脑复制自己的 SSH 公钥到 ~/r2s-login.pub；不要复制私钥。
sudo ./scripts/build.sh /var/tmp/r2s-kali-build "$HOME/r2s-login.pub" https://mirrors.ustc.edu.cn/kali
```

输出目录必须不存在。构建只创建文件，不覆盖运行中的卡。
产出 `nanopi-r2s-kali.img.gz`、`SHA256SUMS` 和软件包清单。
镜像未压缩 2.5 GiB，首次启动时持久化分区自动扩展至卡剩余空间。
Kali rolling 会随时间更新，所以重新构建不保证得到相同版本或相同哈希。

将镜像及校验文件复制回电脑，核验 SHA-256，关机取卡，用支持 `.img.gz` 的刷写工具写入并校验。
**刷卡会清空目标卡，请保留恢复镜像或备用卡。** 插回 R2S，接管理网口，启动后从路由器查询 DHCP 地址：

```sh
ssh -i /path/to/private-key pi@BOARD_IP
```

公开配方只允许密钥登录，没有通用默认密码。`pi` 可以免密码 sudo，因此所选公钥对应的私钥具有管理权限。
主机名 `kali-r2s`，UTC 时区；SSH host key 在首次启动时生成。
管理口 `eth0` 使用 DHCP；第二网口不自动配置，不预设转发、桥接或 NAT。

## 包含什么

Nmap、tcpdump、netcat、socat、DNS 工具、Python、Git、tmux、SSH 等轻量命令行工具。
不安装桌面及完整 Kali 工具全集。zram 为内存的 50%，lz4 压缩；日志存内存，最多 32 MiB。

Pi 和 Node 是可选的刷卡后安装项，参见 [Pi agent 文档](docs/pi-agent.md)。
R2S 负责 agent 和工具执行，模型推理在远端。仓库没有预置任何私人 IP、API 密钥或 SSH 公钥。
构建产物会包含你指定的公钥及你板子的厂商启动分区，应作为个人镜像使用。

## 验收与维护

在板上运行 `bash scripts/healthcheck.sh`，再创建文件、重启，确认文件还在、SSH 恢复、网络正常。
内核仍由厂商维护，不要随意用通用 Kali 内核替换。发生无法启动的问题，可以用原厂镜像重新刷卡恢复。
首版的限制、实测数据和授权来源详见 [validation.md](docs/validation.md) 与 [THIRD_PARTY.md](THIRD_PARTY.md)。

本项目为独立社区项目，不是 Kali、OffSec 或 FriendlyELEC 官方镜像；源码采用 MIT 许可。
