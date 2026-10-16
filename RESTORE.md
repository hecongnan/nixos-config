# 恢复说明

更新于 2026-10-16。以下说明区分已验证事实与待实施方案，尚不是通过演练的完整恢复手册。

## 当前可恢复范围

初始标签 `snapshot-2026-10-15` 表示保存了配置源码与软件清单，不代表完整恢复通过。
2026-10-16，Git 基线 `fe35ab0` 的主机配置离线求值结果与运行、已启动系统的 store 路径一致。
这不等于已经从零构建或恢复了个人数据。当前安装检查因 GRUB EFI 选项冲突求值失败，
修复前不能声称现配置通过全部 flake 检查或安装演练。

恢复需要四组独立材料：

1. 配置源码、Git 历史和 `flake.lock`。
2. 已验收系统及用户 profile 的运行闭包，以及可用的安装介质和恢复工具。
3. 个人资料、可写设置、服务数据与凭据的加密备份。
4. 单独保管的解密密钥、磁盘/引导记录、恢复顺序和验收记录。

lock 固定依赖来源，但不保证未来仍可下载；运行闭包可以重部署保存的二进制，
不等于保存了从源码离线构建所需的全部源码和构建依赖。更高要求必须在断网干净环境实际验证。

## 需要备份的状态

| 内容 | 注意事项 |
| --- | --- |
| 整个用户目录中的真实资料及项目 | 排除可重建缓存前先核对，不跟随 HM/store 符号链接复制整个 store |
| `~/.config/nvim`、`~/.local/share/nvim` | 当前是 LazyVim；包含配置、lazy-lock、插件/解析器及必要编译产物 |
| `~/.config/DankMaterialShell`、`~/.local/state/DankMaterialShell`、`~/.config/niri/dms` | 可写设置，模块只在文件不存在时初始化 |
| `~/.local/share/com.follow.clash` | 含订阅与偏好，只放加密备份 |
| Rime 用户词库、Atuin、浏览器和聊天数据 | 关闭应用或用数据库导出机制保证一致性 |
| SSH 私钥、应用令牌、`~/.local/share/keyrings` | 加密、最小访问；部分账号恢复后仍需重新登录 |
| `/var/lib/private/aurora-password.hash` | 安装激活前恢复，root:root、0600；也可另定新密码方案 |
| NetworkManager 连接与 SSH host keys | root 级备份；克隆新机器通常重新生成 SSH 主机身份 |
| Docker volumes、bind mounts、Compose/env | 先枚举真实路径，数据库做一致性导出；镜像锁 digest 并归档 |
| 实际服务的 `/var/lib` 数据 | 按服务登记，避免把旧目录整体覆盖到不兼容版本 |
| GPT、ESP、EFI 与 Windows/噢易信息 | 保存已核验记录，不把旧 GPT 直接写到不同布局的新盘 |

宿主机实际挂载、Docker 卷及服务状态目录仍需专项采集。
建议本地外置盘和异地各留一份加密备份，密钥另存，定期执行恢复验证。
Btrfs 快照仅用于加速本机恢复，不能替代异地备份。

## 稳定版本归档

每个稳定版本记录 Git commit/tag、lock SHA-256、系统与用户 profile 路径、Nix 版本、
安装介质版本/校验和、数据备份 snapshot ID 和验收结果。

在宿主机执行以下模板前，先把 `DEST` 改为已挂载且空间足够的备份路径，并确认工作区已提交。
本仓库目前没有生成这样的完整离线恢复包。

```bash
cd ~/src/aurora-nixos
git status --short
DEST=/path/to/mounted-backup/aurora-release-2026-10-16
install -d -m 700 "$DEST"
git bundle create "$DEST/config.bundle" --all
sha256sum flake.lock > "$DEST/flake-lock.sha256"
readlink -f /run/current-system > "$DEST/system-path.txt"
readlink -f "$HOME/.nix-profile" > "$DEST/user-profile-path.txt"
nix profile list --json > "$DEST/user-profile.json"
nix --version > "$DEST/nix-version.txt"
nix copy --to "file://$DEST/cache" \
  "$(cat "$DEST/system-path.txt")" \
  "$(cat "$DEST/user-profile-path.txt")"
nix flake archive --no-write-lock-file --to "file://$DEST/cache" --json . \
  > "$DEST/flake-archive.json"
```

还要归档验证过的安装 ISO、安装/分区/修复工具及校验和，并在恢复介质上验证缓存信任与导入流程。
可对自建缓存签名、预置信任公钥，签名私钥另存。运行闭包不一定包含灾备时才需要的工具。
`nix flake archive` 保存递归 flake 输入，不会自动保存所有包的构建期下载。
参见 [nix copy 官方说明](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-copy)。

## 同一台机器恢复

1. 准备上述恢复材料，确认备份可解密且介质能启动。
2. 核对真实磁盘、PARTUUID、文件系统、硬件和 Windows/噢易还原策略。
   历史分区清除脚本仅针对当年的覆盖安装，不能直接作为日常恢复入口。
3. 按待演练确认的挂载/安装流程恢复系统。当前使用 UEFI GRUB，
   不照搬 README 历史记录中的 systemd-boot 操作。
   Windows 项依赖 `B6E9-B042` 及 `/EFI/Microsoft/Boot/OSSBoot.efi`，需实际核验。
4. 在首次激活前安全提供密码哈希及必要网络凭据，恢复所需服务状态并保留正确属主、权限。
   审查维护公钥是否继续授权。
5. 在线可按保存的 lock 构建；离线须先从可信缓存导入已保存系统闭包，
   按演练过的流程用 `nixos-install --system <保存的系统路径>` 安装。
   仅导入 store 不会自动安装引导器、恢复 profile 或完成用户状态恢复。
6. 原 profile 的 22 项已纳入 Home Manager，并恢复了 `pkgs/nvim-system-tools/default.nix`。
   新机器随系统和 HM 构建安装这些软件；用原 inventory 核对，不必重复手动安装旧 profile。
   当前机器已激活该配置并移除旧 profile 重复项，保留旧代际；离线恢复仍需预先保存对应闭包。
7. 解密并恢复个人数据、LazyVim、DMS、FlClash 和服务数据。
   HM 管理的链接让它重新生成，避免直接覆盖产生冲突。
8. 检查本地登录、网络、桌面、输入法、锁屏、应用与数据库。
   课堂视频远端和账号服务需独立确认；部分账号需要重新登录。

## 换一台机器

新建主机配置并复用公共模块。重新生成并审查硬件、磁盘、显示和引导设置。
不直接继承原 PARTUUID、Windows UUID、EDID、i915 绕过参数或 `eno2` 等接口假设。
同一系统二进制也不保证适配不同硬件；按新硬件构建并验证。

## 回滚与恢复演练

普通系统回滚使用引导菜单旧代际，或 `sudo nixos-rebuild switch --rollback`。
随后还需恢复对应源码版本。系统回滚不恢复用户文件、应用数据库或数据库迁移。
GRUB 的 3 个菜单代际也不能替代软件闭包与数据异地留存。

待执行顺序：

1. 修复 `checks.x86_64-linux.installation` 的 EFI 断言冲突，重新完成求值和实际测试。
2. 保存源码异地副本、系统和用户 profile 闭包；建立加密数据备份和独立密钥保管。
3. profile 的 22 项与 nvim-system-tools 定义已纳入配置并激活，命令来源已验收；继续独立纳入真实 Neovim 配置、插件锁和数据。
4. 建立隔离真实磁盘/Windows/显示设置的恢复 VM，在断网干净环境恢复系统与测试数据。
5. 在备用盘或真实硬件验收 GPU、屏幕、音视频、挂起、实际 EFI 和 Windows/噢易行为。

每季度及重大升级后复验，记录恢复耗时、缺失材料与修正步骤。
只有实际完成断网引导、账户登录、软件恢复和代表性数据恢复后，才将对应版本标记为“已验证可恢复”。
