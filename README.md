# Aurora NixOS 桌面

当前状态更新于 2026-10-16。日常维护先读 [START-HERE.md](START-HERE.md)，
恢复边界和准备项见 [RESTORE.md](RESTORE.md)。本文后半保留带日期的历史部署记录；
历史成功记录不代表当前配置或完整数据恢复已经通过验证。

## 当前基线与验证状态

- Git 基线 `fe35ab0` 的主机配置离线求值结果，与运行和已启动系统一致：
  `/nix/store/vyynh7s95ab97148vk1qhz4sk1rasi90-nixos-system-aurora-26.11.20261006.151fa4e`。
  这不是一次从零构建或灾难恢复验证。
- 当前使用 UEFI GRUB，5 秒菜单、3 个引导代际；不再使用首次安装时的 systemd-boot。
- 已增加 Docker/docker-compose、课堂视频本地模块、自定义面板 EDID 和 i915 PSR 绕过设置。
- 用户 profile 另有 22 项软件；实际 Neovim 已是可写 LazyVim 环境，未完整纳入仓库。
- 当前 `nix flake check --offline --no-write-lock-file --no-build` 在 installation 检查失败：
  `boot.loader.grub.efiInstallAsRemovable` 要求关闭 `boot.loader.efi.canTouchEfiVariables`。
  测试配置待修复，尚未重新执行完整构建/VM 安装测试。
- 尚未部署 Git 远端、完整加密数据备份、离线恢复包或干净环境恢复演练。

独立维护的最小桌面，以原配置的桌面集成为蓝本，不依赖原仓库或其中的凭据。
用户名和主机名均为 `aurora`，目标为原 `hcn@10.115.4.26` 的 x86_64 机器。
硬件为 i5-13400、Intel UHD 730、8 GiB 内存、FORESEE 512 GB NVMe，使用 UEFI。

## 已选功能

| 状态 | 内容 |
| --- | --- |
| 启用 | Niri、DMS、Dank Greeter、Super 快捷键、蓝牙、音频、网络、锁屏、截图、剪贴板 |
| 启用 | graphicalBoot：DMS 配色的 Plymouth 启动动画、静默启动与 Greeter 衔接 |
| 启用 | computer-use：补丁版 Niri、Codex Desktop、MCP 包装命令与 aurora 输入权限 |
| 启用 | Fcitx5 + Rime 雾凇全拼、Edge、Kitty、Fish、简单 Starship、zoxide、Atuin、Neovim |
| 启用 | FlClash、桌面登录自动启动到托盘、TUN helper；订阅由朋友首次自行导入 |
| 启用 | Nautilus、归档管理器、图片/PDF 查看器、简单文本编辑器、U 盘自动挂载 |
| 保留关闭开关 | nix-ld、AppImage、direnv、增强终端工具、手机互联 |
| 省略 | Flatpak、Tailscale、打印、DMS 搜索后端、计算器/翻译/番茄钟/日历扩展 |
| 主机启用 | Docker、docker-compose、课堂视频模块（独立于 features 开关） |
| 未在基础桌面声明 | 小鹤、DAE、个人词库、EasyEffects、Steam、Syncthing、投屏、aria2、Wireshark、Mosh；Wireshark 已另装于用户 profile |
| 省略 | 校园网认证、语音与其他个人 AI 工具、特殊内核、特定指纹驱动、额外字体集合、个人开发工作流 |

启用 Atuin 的本地历史和 Ctrl+R，不启用自动同步，不复用任何历史或账号。
`hosts/aurora/features.nix` 管理其列出的功能开关；Docker、课堂视频与引导器另在主机模块配置。
表格描述声明式基础桌面，不代表用户 profile 没有额外安装软件。
FlClash 不向局域网开放额外防火墙端口。

## 配置与文件归属

| 文件 | 管理方式 |
| --- | --- |
| `~/.config/niri/config.kdl`、Fish/Kitty 基础配置、Rime 默认方案 | Home Manager 符号链接至只读 Nix store；改仓库后重建 |
| `~/.config/niri/dms/*.kdl`、DMS settings/session | 首次创建，之后由 DMS 管理；重建保留界面修改 |
| `~/.config/nvim/` | 模块仅在 init.lua 不存在时复制模板；当前已改为本地 LazyVim，整个目录及插件锁需另行保存 |
| `~/.local/share/com.follow.clash/` | FlClash 的本机设置和订阅，可写；首次创建 shared_preferences.json |
| Rime 用户数据库、Atuin 历史 | 用户本机数据，不进入仓库 |

没有硬链接，也没有依赖固定 checkout 路径的 `mkOutOfStoreSymlink`。
固定配置与可写状态分别管理，首次桌面启动不需要克隆配置仓库。
修改 Neovim 初始模板只影响还没有 init.lua 的用户；不会覆盖当前 LazyVim。
当前的 Lua 配置、lazy-lock.json、插件/解析器与必要编译产物需另行纳入配置管理或加密备份。

FlClash 固定为上游 v0.8.99 发布包并校验 SHA-256，修复 NixOS 动态链接。
Linux NativeAssetsManifest 未引用的 Android JNI 库被去除，避免引入无用的 JVM。
静态 Core 保持逐字节不变，打包前后均核对 manifest 中的 Core hash。
helper 由 NixOS systemd 管理，不使用界面内的“安装/卸载服务”操作。
helper 仅接受 UID 1000（aurora）的本地 Unix socket 连接；GUI 不以 root 运行。
FlClash 应用内自动启动关闭，自动更新检查关闭，更新通过此配置包进行。
TUN 权限已准备；导入订阅后在界面选择规则模式、启用 TUN 并启动代理。
订阅和代理规则保留在朋友设备上，不写入 Nix store。

## Graphical boot 与 computer-use

`modules/graphical-boot/default.nix` 沿用蓝本的启动模块：居中的 NixOS 标志、DMS 紫色配色、
Plymouth 动画，以及启动画面到 Dank Greeter 的衔接。
当前主机将引导菜单覆盖为 GRUB、5 秒等待；Plymouth 期间按 Esc 可查看启动日志。默认 `my.graphicalBoot.scale = 1`；
目标机确定后可调整缩放，并在目标硬件配置之外的主机模块添加早期 KMS 驱动。
当前目标已确认使用 Intel UHD 730，`hosts/aurora/platform.nix` 配置早期 i915；缩放保留 1。
另有 `i915.enable_psr=0`，`hosts/aurora/display.nix` 从 initrd 加载去掉 50 Hz 降频模式的面板 EDID；换显示硬件时重新审查。

computer-use 启用上游 `programs.codexComputerUse` 模块的 Niri 窗口坐标与 agent 输入补丁、
ydotool、`/dev/uinput` 权限和 AT-SPI。仅将 aurora 加入 ydotool 组。
桌面与 Greeter 使用相同的补丁版 Niri，agent 操作的窗口显示蓝紫色边框和阴影。
关闭 `my.features.computerUse.enable` 会同时移除这条专属窗口规则，恢复普通 Niri。
Codex Desktop 沿用蓝本的 26.1002.51308 版本及原来的兼容适配，
computer-use 后端独立锁定，不复制账户、会话、MCP 客户端设置或个人技能。
朋友首次启动 Desktop 后自行登录；`codex-computer-use mcp` 提供 stdio MCP 入口。
更新 Niri 或用户组权限后须注销重登，图形登录更新建议 boot 后重启。

新输入 computer-use 锁定到 `0c5f6b90ac1349471dfde07224eece78eb154175`。
保留上游独立依赖锁，以匹配其 CI；现有 nixpkgs、Home Manager、DMS 和 disko 未更新。
已从公共 Cachix API 核对缓存地址和签名公钥，并在系统配置与 flake 中声明：

```nix
extra-substituters = [ "https://niri-computer-use.cachix.org" ];
extra-trusted-public-keys = [
  "niri-computer-use.cachix.org-1:K5LGfljid+PkRn02OLbwsmngqBCoLkbDi9hRMCnsOTg="
];
```

已安装的朋友系统会自动信任该缓存。首次在其他构建机使用时，给 Nix 命令加
`--accept-flake-config`；它仅接受 flake 设置，不会提升普通用户对 Nix daemon 的权限。
若提示 ignoring untrusted substituter，需先把上述设置加入构建机的 Nix daemon 配置，
或由管理员在该次构建时指定相同设置。不要关闭签名校验。
例如管理员可在此目录执行 `sudo nix build --accept-flake-config .#checks.x86_64-linux.desktop --no-link`，
在首次构建时读取 flake 中的公共缓存配置。
缓存命中取决于依赖和补丁一致；此次 Niri derivation 与上游 CI 输出一致。
蓝本的 Desktop 兼容覆盖仍会生成自己的衍生包，其后端与依赖可复用缓存。

参考：[上游 Cachix 使用说明](https://github.com/lihaoze123/niri-computer-use/blob/0c5f6b90ac1349471dfde07224eece78eb154175/docs/ci.md)。

## SSH 与密码

`keys/maintenance.pub` 是当前维护设备 `chumeng@class` 的用户公钥，允许登录 root 和 aurora。
root 只允许公钥登录，SSH 密码登录关闭。未复制维护者私钥、原仓库的 secrets 或个人账号登录数据。
朋友的本地登录和 sudo 密码由 `/var/lib/private/aurora-password.hash` 提供，安装时单独注入。
该路径固定，与用户名无关；如果以后改变 UID/GID，需要同时调整 helper 所属用户配置。

## 当前目标与磁盘布局

`hosts/aurora/hardware-configuration.nix` 已在临时安装环境中自动生成，没有手工改动。
硬件、目标分区及密码准备已完成，`installationReady = true`。
`aurora-preview` 使用整盘虚拟磁盘 `/dev/vda`，只用于 VM 演练，不得用于真实安装。

已选择只覆盖原 Arch 的 p9、p10，保留 p1…p8 和原有 Windows EFI 启动项。
父磁盘为 `/dev/disk/by-id/nvme-FORESEE_XP1000F512G_NFE476Q023944`。

| 分区 | 安装用途 | 稳定标识 |
| --- | --- | --- |
| p9，488 MiB | FAT32 `/boot`，当前为 UEFI GRUB | PARTUUID `82583d67-296c-4c37-a6b6-976a4cbbe812` |
| p10，99.5 GiB | Btrfs root/home/nix | PARTUUID `f63cafe7-af68-48d7-a02e-c021f166bbf0` |

`diskLayout = "existing-partitions"`：disko 仅声明这两个分区，均 `destroy = false`，没有 GPT 重建操作。
ESP 显式使用 `mkfs.vfat -F 32`；488 MiB 分区使用默认参数会生成 FAT16，可能被固件跳过。
清除已批准的旧 Arch 文件系统签名后，由 disko 创建新文件系统和子卷。
不移动、不缩放分区；p10 中原 Arch 的 `/home` 也会清空。
当前不启用 LUKS 或磁盘休眠，使用 zram；有限的 ESP 只保留 3 个启动菜单代际，不自动清理系统代际。
Windows 在另一块 ESP，可通过固件启动菜单选择原 Windows Boot Manager；不向 NixOS ESP 复制 Windows 文件。
`modules/disk-whole.nix` 保留原整盘方案供 VM 使用，真实目标明确不采用它。

当前启动器为 UEFI GRUB；`hosts/aurora/default.nix` 强制关闭公共磁盘模块里的 systemd-boot，
设置 5 秒菜单与 3 个引导代际。Windows 菜单项按文件系统 UUID `B6E9-B042` 查找 ESP，
链式启动 `/EFI/Microsoft/Boot/OSSBoot.efi`。这里记录的是源码配置，
2026-10-16 未重新验证固件启动项、ESP 文件或 Windows 实际启动。
不要按首次安装的 systemd-boot 菜单说明操作，也不要未经核验替换链式启动文件。
可使用 `sudo systemctl reboot --firmware-setup` 进入支持此功能的固件设置。
固件 Boot 编号可能随重建变化，应按实际分区和路径辨认。
进入 Windows 前先处理噢易的分区还原策略；直接选择 p1 也不能保证 Windows 内的还原驱动不重置布局。

换目标机器时必须重新检查硬件和分区，不能复用本机的路径和批准脚本：

```bash
ssh root@<IP> 'lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL; ls -l /dev/disk/by-id; lspci -nn'
ssh root@<IP> 'test -d /sys/firmware/efi && echo UEFI || echo Legacy'
```

目标机需要允许维护公钥登录。有线网络可保持 SSH 连通。
本次目标外网被校园认证页拦截，因此 kexec 包在维护机下载，经 SSH 上传；闭包在本机构建后完整传输。
安装不关闭 TLS 校验，也不依赖目标机的 FlClash。重启后仍需朋友自行完成校园网网页认证。

在临时 NixOS 环境生成硬件文件（不手改自动生成的硬件配置）：

```bash
ssh root@<IP> 'nixos-generate-config --no-filesystems --show-hardware-config' \
  > hosts/aurora/hardware-configuration.nix
```

文件系统由 disko 声明。核对目标 CPU/GPU/网卡驱动，按需要添加硬件专属配置。
当前目标的 RTC 使用北京时间，新系统配置 `time.hardwareClockInLocalTime = true`，与保留的 Windows 协调。

## 构建与预览

当前 installation 检查因上述 GRUB EFI 断言失败。以下是构建/测试入口，
不能据此推断它们在现配置下全部通过；先修复专用测试的 EFI 设置，再重新运行检查和 VM 演练。

```bash
cd ~/src/aurora-nixos
git status --short
nix fmt

# 硬件未填写时也可检查完整桌面和虚拟磁盘脚本；不激活本机系统
nix build .#checks.x86_64-linux.desktop --out-link result-desktop
nix build .#checks.x86_64-linux.disko --out-link result-disko
nix build .#flclash --out-link result-flclash
nix build .#checks.x86_64-linux.flclash-loader --no-link
nix build .#checks.x86_64-linux.partition-safety --no-link

# 虚拟机演练，不指定真实目标机
nix run github:nix-community/nixos-anywhere/b6be7b277b468d55082584441cbef1fed8530eb3 -- \
  --flake .#aurora-preview --vm-test
```

当前真实硬件和磁盘配置已完成，可检查求值并构建真实主机；换机器时先把 installationReady 设为 false：

```bash
git status --short
nix flake check --no-build
nix build .#nixosConfigurations.aurora.config.system.build.toplevel --out-link result-aurora
nix build .#nixosConfigurations.aurora.config.system.build.diskoScript --out-link result-aurora-disko
```

`flake.lock` 沿用蓝本已锁定的 nixpkgs、Home Manager、DMS 和 disko 版本，另加入已选择的 computer-use 输入。
不因准备朋友版而更新原仓库依赖。`stateVersion = "26.05"` 是此次初始数据兼容版本，后续升级保留。

## 首次覆盖安装的历史流程

本节保存 2026-10-09 的 Arch 覆盖安装过程，不是当前恢复系统的已验证操作手册。
现系统已切换为 GRUB，安装测试存在待修复问题；恢复以 RESTORE.md 的准备项与重新演练结果为准。

仅在目标磁盘、布局、硬件和实际构建全部检查完成后执行。
本次仅格式化已批准的 p9、p10，不运行整盘擦除。以下是首次覆盖 Arch 的流程，不能用于日常重建。

本次沿用 hcn 的密码：从原 Arch 的 shadow 中取得哈希并直接写入仓库外的 extra-files，未显示或提交哈希。
网络连接和备份同样位于维护机 `~/.cache/aurora-install-10.115.4.26.*`，目录权限 0700。
准备新密码时也可在仓库外交互生成：

```bash
extra_dir=$(mktemp -d)
install -d -m 700 "$extra_dir/var/lib/private"
nix shell --inputs-from . nixpkgs#mkpasswd -c mkpasswd --method=yescrypt \
  > "$extra_dir/var/lib/private/aurora-password.hash"
chmod 600 "$extra_dir/var/lib/private/aurora-password.hash"
```

Wi-Fi 安装需把目标安装环境中要保留的 NetworkManager 连接文件放到
`$extra_dir/etc/NetworkManager/system-connections/`，权限 0600，重启后才能继续自动联网。
这些文件可能包含密码，始终放在仓库外；也可使用有线连接后再由朋友配置 Wi-Fi。

```bash
# 先仅进入临时安装环境，生成硬件，不格式化
nix run github:nix-community/nixos-anywhere/b6be7b277b468d55082584441cbef1fed8530eb3 -- \
  --flake .#aurora --target-host hcn@10.115.4.26 \
  --kexec /path/to/nixos-kexec-installer.tar.gz --phases kexec \
  --generate-hardware-config nixos-generate-config hosts/aurora/hardware-configuration.nix

# 构建真实主机、检查 partition-safety，并核对 GPT 备份后，才清除原 Arch 签名
ssh root@10.115.4.26 bash -s -- \
  /dev/disk/by-id/nvme-FORESEE_XP1000F512G_NFE476Q023944 \
  /dev/disk/by-partuuid/82583d67-296c-4c37-a6b6-976a4cbbe812 \
  /dev/disk/by-partuuid/f63cafe7-af68-48d7-a02e-c021f166bbf0 \
  < scripts/prepare-arch-partitions.sh

# 本地已完整构建；由 disko 格式化和挂载，由 nixos-anywhere 安装
nix run github:nix-community/nixos-anywhere/b6be7b277b468d55082584441cbef1fed8530eb3 -- \
  --flake .#aurora --target-host root@10.115.4.26 \
  --phases disko,install --extra-files "$extra_dir" --copy-host-keys \
  --build-on local --no-substitute-on-destination

# 核对 GPT、保留分区、密码文件和服务配置后，再重启
ssh root@10.115.4.26 reboot
```

批准脚本检查父磁盘、分区号、PARTUUID、原文件系统 UUID 及未挂载状态，两项都通过后才擦除签名。
它不修改 GPT，装成 NixOS 后原 UUID 改变，因此会拒绝再次清除。
备份保留到实际验收结束再删除；目标机保留所需的密码 hash 和网络配置。
重启后核对 SSH 主机指纹和 IP，通过 root 公钥登录；验证本地 aurora 登录、sudo 和锁屏。
`nixos-anywhere` 只用于首次安装，日常更新用 nixos-rebuild。

## 常用快捷键

| 按键 | 功能 |
| --- | --- |
| Super+Enter / Space | 终端 / 启动器 |
| Super+E / B / L | 文件管理器 / Edge / 锁屏 |
| Super+V / , | 剪贴板 / DMS 设置 |
| Super+方向键 / Shift+方向键 | 焦点移动 / 窗口或列移动 |
| Super+1…5 / Ctrl+1…5 | 切换工作区 / 移动列到工作区 |
| Super+Q / Shift+Q | 关闭窗口 / 确认退出会话 |
| Super+F / Shift+F | 最大化列 / 全屏 |
| Print / Ctrl+Print / Alt+Print | 区域 / 全屏 / 窗口截图 |
| Super+Shift+?（Slash） | 显示快捷键帮助 |

不固定屏幕型号、分辨率或 DPI；在 DMS 中调整输出和缩放。
默认 5 分钟空闲锁屏，10 分钟关闭显示器，挂起前锁屏。

## 启动验收和后续维护

真实目标机需验证登录、中文输入、网络、蓝牙、扬声器/麦克风、锁屏、挂起唤醒、U 盘和截图。
验证 Edge 文件选择和屏幕共享；验证 FlClash 托盘、helper、TUN、代理及局域网直连。

```bash
systemctl --failed
systemctl status flclash-helper
systemctl --user status dms fcitx5-daemon flclash swayidle
niri validate
```

正常更新先 build。图形登录变更使用 boot 后重启，不在活动桌面中切换登录管理器：

```bash
nixos-rebuild build --flake .#aurora
nixos-rebuild boot --flake .#aurora --target-host root@<IP>
```

SSH 公钥访问与 TUN helper 的权限代表已经选定的远程维护和本机代理能力。
不自动清理旧系统代际，保留回滚入口。

## 历史验证与压缩包

以下是 2026-10-08/09 的部署记录，仅对应当时配置与产物。
2026-10-16 的源码匹配结果、当前安装检查失败和恢复缺口见本文顶部；
旧压缩包与历史测试不能证明当前系统可完整离线恢复。

2026-10-08 已通过完整桌面、disko 脚本和 FlClash 包构建，以及 Niri 配置校验。
固定版本 nixos-anywhere 的 `aurora-preview --vm-test` 已通过：UEFI/Btrfs 分区、安装、重启、
Home Manager 首次激活、SSH 服务、FlClash helper 的用户允许/root 拒绝检查、
雾凇词库部署、Neovim 加载本地配置和重新激活后保留本地修改。
预览入口包含共享 Nix store 的测试兼容设置，不用于真实主机。
此演练没有验证实际 GPU、启动动画与 Greeter 衔接的显示效果、图形登录或订阅代理流量；这些仍需目标机验收。
当时真实入口因 installationReady 和磁盘占位保护断言而停止。当前已填写目标硬件和分区。

2026-10-09 加入 graphicalBoot 和 computer-use 后重新完成桌面与分区脚本构建。
再次通过 nixos-anywhere VM 安装与重启，新增验证 ydotool 服务、aurora 的用户组与 uinput 访问、
补丁 Niri 加载 agent 窗口规则、computer-use 命令入口；原有 helper、雾凇部署和 Neovim 保留检查也通过。
已核对公共缓存中存在相同 derivation 的补丁版 Niri，签名标识与配置公钥一致。
首次构建沿用本机已有产物，没有修改本机的缓存信任或激活系统。

2026-10-09 已完成真实目标的硬件生成、主机构建和全套 flake 求值检查。
新增 partition-safety VM 检查通过：前八个模拟分区的完整内容哈希及 GPT 不变，
错误分区被批准脚本拒绝，重复运行 disko 保留已有文件。
实际安装仅格式化 p9、p10，已通过 nixos-anywhere 完成本地闭包传输和 systemd-boot 安装。
重启前核对了主、备 GPT 逐字节一致，p1…p8 的分区属性和文件系统 UUID 不变，
Boot0000 和 Boot0007 两个 Windows 启动项逐行一致。ESP 使用约 71 MiB，剩余约 418 MiB。
已确认 aurora 的 shadow 哈希与原 hcn 密码哈希相同，root/aurora 都具有指定维护公钥，
两份原 NetworkManager 连接文件以 root:root、0600 权限注入。密码哈希和备份不进入源码包。

首次重启进入 Windows/噢易还原环境后，观察到分区表被改回八分区布局，p5 扩大、p9/p10 条目消失，
EFI 启动项也被重置。通过 U 盘启动后按原扇区偏移只读检查，NixOS 文件系统及子卷仍在。
确认 p5 的 NTFS 文件系统仍为原来大小后，恢复原主、备 GPT，逐字节复核一致；
仅将 p9 从 FAT16 修正为 FAT32 并恢复原启动文件，p10 未重新格式化。
配置和 partition-safety 测试已补上显式 FAT32 及实际格式版本检查，测试通过。
重建 p9 的 NixOS 启动项并设为默认及下一次启动项，保留现有 Windows 和噢易分区。
再次进入噢易还原环境可能重置布局；使用 Windows 前，需要在其管理界面处理分区还原策略。

修复后成功从 p9 的 systemd-boot 启动实际 NixOS，SSH 主机指纹与原 Arch 的保留指纹一致，
启动后的主、备 GPT 再次复核与原备份逐字节一致。系统没有失败单元，Home Manager 首次激活成功，
Greeter、NetworkManager、SSHD、FlClash helper、ydotool 服务正常；用户 Niri、DMS、Fcitx5、
swayidle、PipeWire 和 WirePlumber 服务正常。FlClash 启动错误界面也会返回退出码 0，
服务状态无法单独证明应用正常；随后根据实际界面发现了 Rust 库搜索路径遗漏并修复。
实际 Rime 雾凇方案已部署，Niri 配置校验、可写 Neovim 配置加载、aurora 的 uinput 权限检查通过。
用户已现场确认登录和桌面正常。FlClash 订阅/TUN 流量、computer-use 实际模型操作、音视频设备、
挂起唤醒及 Windows 的还原策略仍需按实际使用验证。

FlClash 包的启动脚本已加入自带 `lib/` 目录，修复 `librust_api.so` 动态加载失败。
新增检查通过实际启动脚本进入应用进程，在显示界面前尝试加载该库：旧包复现失败，修正版通过。
修正后完成主机构建和 flake 求值检查，应用更新未重启桌面会话；实际启动日志已进入 APP 初始化阶段，
随后应用记录正常退出，helper 服务继续运行。用户已现场确认主界面正常打开，动态库报错消失。
仍需导入订阅后验证代理流量。

`aurora-nixos.tar.zst` 是配置源码包，包含依赖锁、公钥和本文档，不包含离线安装所需的二进制缓存。
打包排除了 `.git`、`.jj`、`.work`、构建结果和测试日志；不含私钥、密码或订阅。

```bash
sha256sum -c aurora-nixos.tar.zst.sha256
tar --zstd -xf aurora-nixos.tar.zst
cd aurora-nixos
```

解包后的目录可独立使用，无需原仓库；如果继续使用 jj，可执行 `jj git init`。

参考：[nixos-anywhere](https://nix-community.github.io/nixos-anywhere/quickstart.html)、
[安装凭据](https://nix-community.github.io/nixos-anywhere/howtos/secrets.html)、
[FlClash](https://github.com/chen08209/FlClash)、[雾凇拼音](https://github.com/iDvel/rime-ice)。
