# nixos-config

Aurora 的个人 NixOS 配置：使用 Flake 锁定依赖，以 NixOS 模块管理系统，
以集成式 Home Manager 管理用户环境，使用 Git 保存变更历史。
当前 checkout 位于 `~/src/aurora-nixos`；远端为 GitHub 私有仓库
[hecongnan/nixos-config](https://github.com/hecongnan/nixos-config)，本地 remote 名称为 `origin`。

## 当前入口与验证状态

- 主机入口：`flake.nix` → `nixosConfigurations.aurora` → `hosts/aurora/default.nix`。
- 用户入口：`modules/nixos/home-manager.nix` → `home/aurora/default.nix`。
- 平台：`x86_64-linux`，主机名和用户名均为 `aurora`。
- 主系统 Nixpkgs 保持原 `nixos-unstable` tarball 来源，锁定 `151fa4e8ddfdd8dd25d945ad94ed54a13de9f6e4`。
- `system.stateVersion` 与 `home.stateVersion` 均保留 `26.05`；它们是数据兼容版本，不随软件更新递增。
- 2026-10-16 本次目录迁移的各阶段均通过 `nixos-rebuild build`，最终系统产物与迁移前一致；未执行 switch。
- `checks.x86_64-linux.installation` 原有 GRUB EFI 断言冲突尚未修复，不能宣称全部 flake 检查或恢复演练通过。
- 用户 profile 的 22 项软件已按原软件输出和优先级纳入 Home Manager，并已激活；旧 profile 的重复条目已移除，旧代际保留。当前 LazyVim 配置和可写应用数据仍需单独备份。
- 软件声明化已通过离线系统构建；新 HM 环境的 250 个原 profile 命令均解析到原可执行文件。

日常操作见 [START-HERE.md](START-HERE.md)，恢复边界和备份清单见 [RESTORE.md](RESTORE.md)。
[迁移记录](docs/migration-2026-10-16.md)说明本次变动；
[历史部署说明](docs/deployment-history.md)保留原有功能细节、快捷键及安装历史。

DMS 托盘点击聚焦通过固定版本的独立补丁仓库自动部署，恢复系统时无需手动安装。
部署与已有本地覆盖的迁移见 [托盘聚焦说明](docs/niri-tray-focus.md)。

当前 DMS/niri 设置、quickCapture、VS Code 启动修复、Neovim 固定配置、
Codex CLI 及外观/输入法设置已纳入恢复配置，见 [桌面恢复清单](docs/desktop-restoration-2026-10-20.md)。

## 目录结构

```text
.
├── flake.nix / flake.lock
├── hosts/aurora/              # 本机入口、硬件、引导、显示和课堂网络参数
│   ├── default.nix
│   ├── machine.nix
│   ├── hardware-configuration.nix
│   ├── boot.nix
│   ├── features.nix
│   ├── platform.nix
│   ├── display.nix
│   └── classroom.nix
├── modules/nixos/            # 可复用系统功能与集成
├── home/aurora/              # 用户环境
├── assets/                   # 固定配置与首次初始化模板
├── pkgs/                     # FlClash 与恢复的 nvim-system-tools 包定义
├── oseasy-video-nixos/       # 课堂视频通用模块、打包及 Python 源码
├── keys/                     # 已授权的维护公钥
├── inventory/                # 仓库外安装的软件与工具清单
├── scripts/                  # 历史安装工具，日常重建不运行
├── tests/                    # 预览安装、分区保护和软件加载检查
├── docs/                     # 迁移与部署历史
├── START-HERE.md / RESTORE.md
└── .gitignore
```

`hosts/aurora/edid/` 和三份 `platform.nix.before-*` 历史调试副本仍保留；副本未被导入。
磁盘实现仍在参数化的系统模块中，具体设备和分区标识来自本机 `machine.nix`。

## 模块职责

| 文件 | 职责 |
| --- | --- |
| `hosts/aurora/default.nix` | 组合当前主机模块；导入顺序保留原列表合并结果 |
| `hosts/aurora/machine.nix` | 用户名、主机名、安装确认及磁盘和分区参数 |
| `hosts/aurora/hardware-configuration.nix` | 自动生成的硬件设置，原样保留 |
| `hosts/aurora/boot.nix` | 本机 GRUB、菜单和 Windows EFI 链式启动 |
| `hosts/aurora/features.nix` | 本机功能开关 |
| `hosts/aurora/platform.nix`、`display.nix` | Intel 显示绕过、RTC、自定义面板 EDID |
| `hosts/aurora/classroom.nix` | 本机课堂服务地址、接口和端口；导入通用实现 |
| `modules/nixos/base.nix` | 机器选项、安装断言、Nix、区域设置、基础软件和系统 stateVersion |
| `modules/nixos/networking.nix` | 主机名、NetworkManager、nftables 和防火墙 |
| `modules/nixos/users.nix` | 用户与组、登录 shell、密码文件引用、SSH 授权及 sshd |
| `modules/nixos/home-manager.nix` | NixOS 集成式 HM 接线，保留原 useGlobalPkgs/useUserPackages |
| `modules/nixos/desktop.nix` | Niri、桌面系统服务、音频和字体 |
| `modules/nixos/docker.nix` | Docker、Compose 与原用户组权限 |
| `modules/nixos/features.nix` | 功能选项声明及蓝牙等实现 |
| `modules/nixos/greeter.nix`、`graphical-boot/` | 登录界面和 Plymouth 衔接 |
| `modules/nixos/computer-use/` | 原有桌面输入集成和软件兼容覆盖 |
| `modules/nixos/flclash.nix` | 系统 TUN helper；用户 GUI 在 HM 中管理 |
| `modules/nixos/disk.nix`、`disk-whole.nix` | 现有分区及整盘预览方案，不在日常维护中执行格式化 |
| `home/aurora/default.nix` | 用户入口、home.stateVersion、MIME 和用户服务 |
| `home/aurora/packages.nix` | 用户软件列表，包含原 profile 的 22 项；由用户入口读取 |
| `pkgs/nvim-system-tools/default.nix` | 从原构建记录恢复的 Neovim 开发工具集合，原软件顺序与链接范围不变 |
| `home/aurora/desktop.nix` | DMS、Niri、主题、光标和空闲锁屏 |
| `home/aurora/input.nix` | Fcitx5/Rime 和词库方案 |
| `home/aurora/shell.nix` | Fish、Starship、Atuin、Kitty、Neovim 初始模板 |
| `home/aurora/flclash.nix` | FlClash 用户客户端及自启动 |

当前没有 HM 管理的 Git 身份配置，因此没有创建空的 `git.nix`；Fish 与相关工具保留在 `shell.nix`。

## 添加软件或修改服务

用户常用软件加到 `home/aurora/packages.nix` 的列表；系统基础工具加到 `modules/nixos/base.nix`。
桌面、输入法或 shell 专属软件放在对应模块。修改已有服务时编辑其所属文件。
新增可复用系统服务模块后，由 `hosts/aurora/default.nix` 导入；本机设备参数放在 `hosts/aurora/`。

先看 `git status` 和 `git diff`，新文件审阅后逐个 `git add`，再构建。
Git Flake 不会自动包含未跟踪的新文件。避免使用 `git add .` 将私人文件意外加入。
原 profile 的 22 项已完成声明化，构建表达式使用当前锁定 Nixpkgs，保留原输出和优先级。
Neovim 保留 profile 中优先级为 4 的原包装版本，优先于现有 HM 程序模块产生的版本；原初始化逻辑不变。
后续经授权已完成 switch，并在核验实际用户环境后移除旧 profile 的 22 个重复条目；清理后再次核验 250 个命令来源一致，旧代际保留。

## 构建与应用

```bash
cd ~/src/aurora-nixos
nixos-rebuild build --flake .#aurora --no-write-lock-file
readlink -f result
git diff
```

build 生成系统产物，不激活配置。已有全部依赖时可加 `--offline`；离线缺依赖时先检查原因。
确认构建结果和影响后，再由使用者决定是否执行：

```bash
sudo nixos-rebuild switch --flake .#aurora --no-write-lock-file
```

引导、内核、驱动或图形登录变更需另行审查；可选择 `nixos-rebuild boot` 后重启验收。
目录整理阶段仅 build；后续软件声明化经授权已执行 switch。未执行 boot、重启、分区脚本、nixos-anywhere 或 disko 格式化。
`aurora-preview` 只用于 VM，不得作为真实机器安装入口。

## 更新 Flake

依赖升级应是独立变更，保持工作区干净。仅在决定升级后手动执行，例如：

```bash
nix flake update nixpkgs home-manager
git diff -- flake.lock
nixos-rebuild build --flake .#aurora --no-write-lock-file
```

不指定输入的 `nix flake update` 会更新全部输入。computer-use 使用独立依赖与兼容补丁，
升级前分别检查；不要为统一依赖而强制合并。本次没有更新 `flake.nix` 或 `flake.lock`。
升级软件时也不修改两个 stateVersion。

## 回滚

未激活的目录修改可通过独立 Git 提交回退，再重新 build。
系统已切换后，可从启动菜单选择旧代际，或确认影响后执行 `sudo nixos-rebuild switch --rollback`。
随后使配置源码对应回目标提交。系统回滚不恢复用户文件、应用数据库或已发生的数据迁移。
保留旧 Generation 和 Nix Store；GRUB 菜单的三个代际不代表完整异地备份。

## 在新机器复现

1. 获取仓库和锁文件；未来私有 GitHub 仓库需先完成个人认证，不把 Token 写入配置。
2. 新建 `hosts/<新主机>/`，重新生成并审查硬件配置、磁盘布局和引导方式。
3. 在 `flake.nix` 增加新的 `nixosConfigurations`，复用适用的系统模块。
4. 用户名相同时可复用 `home/aurora/`；其他用户名应创建对应用户入口并调整 HM 接线。
5. 不照搬当前磁盘/PARTUUID、Windows EFI 项、EDID、i915 参数或网络接口；安全提供仓库外密码文件等凭据。
6. 构建新主机配置，经磁盘与备份确认后按独立安装流程部署，恢复用户数据并逐项验收。原 profile 软件会随 HM 安装，旧软件清单用于核对。

当前主机是 x86_64-linux；其他架构还需审查所有输入和本地软件包支持。
锁文件不保证未来所有下载源仍可用，离线恢复还需归档闭包和恢复工具，并实际演练。

## 单独备份与隐私

源码仓库不能替代数据备份。至少单独加密保存个人文件、真实 LazyVim 配置与插件锁、
DMS/Niri 可写设置、FlClash 订阅、Rime 用户词库、Atuin、浏览器和聊天数据、密钥与凭据、
Docker volumes/bind mounts 和实际服务数据。系统密码文件、NetworkManager 连接及 SSH host keys
需按权限单独准备；新设备通常重新生成主机身份。完整清单见 [RESTORE.md](RESTORE.md)。

公钥和软件校验 hash 不是私钥；内网地址、设备标识及部署历史仍需上传前审核。
`.gitignore` 不会清除已跟踪文件或 Git 历史。远程仓库保持 Private，推送前复查文件与提交历史。
GitHub CLI 通过浏览器认证；认证信息保留在仓库外，不把 Token 写入 remote URL 或配置源码。

本次软件声明化的逐项核对与验收边界见 [profile 迁移记录](docs/profile-migration-2026-10-16.md)。
