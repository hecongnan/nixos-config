# 我的 NixOS 配置仓库

更新于 2026-10-16。本仓库保存系统配置、声明的软件和固定配置模板。
个人资料、可写应用设置和凭据需要单独加密备份；目前尚未部署完整备份与恢复演练。

## 当前系统

- 主机入口：`nixosConfigurations.aurora`，用户名 aurora，UID/GID 1000。
- 引导器：UEFI GRUB，5 秒菜单，最多 3 个引导代际；主机覆盖了公共模块中的 systemd-boot 设置。
- Windows 菜单按文件系统 UUID `B6E9-B042` 查找，启动 `/EFI/Microsoft/Boot/OSSBoot.efi`。
  这是当前配置值，本次没有重新验证实际 EFI 文件、启动项或噢易还原策略。
- 桌面：补丁版 Niri、DMS、Dank Greeter、Fcitx5/Rime、PipeWire、FlClash 和 computer-use。
- Docker/docker-compose 在 `modules/nixos/docker.nix` 启用，aurora 属于 docker 组。
- 课堂视频参数在 `hosts/aurora/classroom.nix`，实现来自受 Git 跟踪的 `oseasy-video-nixos/`；配置接口 `eno2`、远端 `10.115.3.82:17778`。
  远端服务与校园网络不由本仓库重建。
- 显示配置包括 `i915.enable_psr=0` 和自定义面板 EDID；换机时重新审查。

`hosts/aurora/features.nix` 仅管理其列出的功能开关；Docker、课堂视频和引导器另由主机模块设置。

## 验证状态

2026-10-16，当前 Git 基线 `fe35ab0` 的主机离线求值结果与运行、已启动的系统路径一致：

```text
/nix/store/vyynh7s95ab97148vk1qhz4sk1rasi90-nixos-system-aurora-26.11.20261006.151fa4e
```

这不代表个人目录已受配置覆盖，也不表示从零重新构建或完整恢复已通过。

当前 `nix flake check --offline --no-write-lock-file --no-build` 在
`checks.x86_64-linux.installation` 失败：GRUB 的 `efiInstallAsRemovable` 与
`boot.loader.efi.canTouchEfiVariables` 冲突。需修复测试配置并重新验证，不能引用旧 README 的历史通过记录证明当前测试通过。

## 日常修改

```bash
cd ~/src/aurora-nixos
nvim assets/niri.kdl
git diff
# 新文件先审查并 git add；Git flake 不会自动纳入未跟踪文件
nixos-rebuild build --flake .#aurora
# 普通配置变更确认影响后应用
sudo nixos-rebuild switch --flake .#aurora
# 审查后只提交本次相关文件
git add assets/niri.kdl
git commit -m "调整桌面快捷键"
```

图形登录、驱动、内核和引导变更使用 `sudo nixos-rebuild boot --flake .#aurora`，再重启验收。
稳定发布应先提交源码，再构建并记录对应 commit、系统路径与备份版本。
日常重建不运行 disko 格式化、nixos-anywhere 或历史分区清除脚本。

## 文件位置

- `flake.nix` / `flake.lock`：入口和依赖锁，一起提交。
- `hosts/aurora/`：硬件、磁盘、引导与显示配置。
- `modules/nixos/`：可复用系统模块。
- `home/aurora/`：Home Manager 用户配置。
- `assets/`：固定配置与首次初始化模板。
- `oseasy-video-nixos/`：本地模块和运行源码，必须随仓库保存。
- `inventory/`：2026-10-15 采集的额外用户软件清单，不含应用数据。
- `RESTORE.md`：当前恢复边界、准备项和恢复顺序。
- `README.md`：当前目录、模块职责、维护和复现方法。
- `docs/deployment-history.md`：保留原部署细节和带日期的历史记录。

## 软件与可写设置

2026-10-16 实时 profile 仍有 22 项额外软件，尚未统一迁入声明式配置。
其中 21 项有 Nixpkgs 属性；以 `inventory/user-profile.json` 的属性、固定来源与 priority 为线索，
不要直接使用会漂移的 `nixpkgs#软件名` 作为长期恢复说明。
例如按原固定来源恢复 Chrome：

```bash
NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure --priority 5 \
  github:NixOS/nixpkgs/151fa4e8ddfdd8dd25d945ad94ed54a13de9f6e4#google-chrome
```

`nvim-system-tools` 是无来源属性的本地构建结果；清单里的 store 路径不是下载地址。
需找回构建表达式，或先保存其运行闭包。迁移软件时审查现有 Neovim/Vim 重复项、PATH 和应用优先级。

当前 `~/.config/nvim` 已是可写的 LazyVim 环境，不是仓库 `assets/init.lua` 的简单模板。
应保存整个配置、`lazy-lock.json`、必要的插件/解析器及编译结果；锁文件不能替代离线插件归档。
DMS 设置、`~/.config/niri/dms`、FlClash 订阅、Rime 用户词库和 Atuin 数据也不会自动同步回仓库。

## 保存副本与隐私

目前没有 Git remote，尚未完成加密数据备份、独立密钥保管或离线恢复演练。
本地 Git 历史不能抵抗磁盘损坏。下一步应保存异地源码副本、系统和用户 profile 运行闭包，
并建立带独立恢复密钥的数据加密备份，参见 `RESTORE.md`。

私钥、API Key、密码哈希、订阅、Wi-Fi 凭据、浏览器资料与聊天数据库不以明文提交。
`keys/maintenance.pub` 是授权公钥；配置继续允许其登录 root/aurora，变更前需审查维护访问。
硬件标识、用户名及部署历史仍在仓库中，上传前应审查可见范围。
