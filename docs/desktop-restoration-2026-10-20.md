# 2026-10-20 桌面与编辑器恢复配置

本次保存的是可公开审查的配置、固定源码和安装来源；不包含登录令牌、代理订阅、
浏览器会话、SSH 私钥或命令/启动器历史。按正常 NixOS 部署流程恢复时无需另行手动
安装 quickCapture、克隆 Neovim 配置或复制 VS Code 的旧诊断脚本。

## 已纳入

| 内容 | 保存与恢复方式 |
| --- | --- |
| DMS 设置、控制中心布局、托盘隐藏偏好 | assets/desktop-state 中的选择性快照，首次启动缺失时复制 |
| niri 的 DMS 片段 | 包含间距 4、圆角 16、eDP-1 1920×1080@60、输入和浮动规则；缺失时初始化 |
| quickCapture 5.6.1 | vendor/quickCapture 保存上游固定提交的原始 127 文件和 MIT 许可；HM 部署插件源码，初始设置启用 |
| Papirus-Dark | QT6/DMS 的图标选择和 qt6ct 配置；保留原有 GTK Adwaita 设置 |
| Fcitx 界面主题和通知偏好 | 首次缺失时恢复 classicui.conf、notifications.conf；输入方案仍由 input.nix 管理 |
| VS Code 启动修复 | Nix 生成 code-x11 包装器及两个桌面入口，保留 X11、disable-gpu，不再依赖 Documents/Codex 工作目录或诊断日志 |
| Neovim | flake input 固定 hecongnan/nvim-config 的 e62ab4660fa4a893971ec4c8811f804c9d557ce7，首次复制完整可写配置 |
| Neovim 工具链 | NVIM_SYSTEM_TOOLS 指向 Nix 构建的工具环境，替代已清空的旧 ~/.nix-profile；Mason 不接管这些工具 |
| Codex CLI | pkgs/codex-cli 固定官方 0.162.1 x86_64-linux-musl 完整发布包和 SHA-256，包含 code-mode-host 与资源 |
| 用户命令 PATH | home.sessionPath 和 .profile 纳入 ~/.local/bin；固定 CLI 入口由 HM 创建 |

Codex 官方包来源：
https://github.com/openai/codex/releases/download/rust-v0.162.1/codex-package-x86_64-unknown-linux-musl.tar.zst
发布 API 提供的压缩包 SHA-256：
`bd24d02be678894b47bc565bd2da8d47a05e3a7dd0b6ef66aa957299b24ec8f2`。
CLI 与账号配置分开管理，登录信息不复制进 Nix store。
官方 CLI 安装说明：https://developers.openai.com/codex/cli/

## 恢复与更新边界

- 快照仅初始化缺失文件，不覆盖已在 GUI 中修改的现有设置；启动器查询历史、
  最近媒体信息、用量记录和账户数据没有进入快照。
- Home Manager 管理 qt6ct、插件源码、CLI 链接和 VS Code 桌面文件；本仓库现有
  backupFileExtension=hm-backup 用于保留未托管的原文件。若同名备份已存在，
  激活可能停止，应先另存这些备份，不能直接删除旧配置。
- quickCapture 源码是固定的只读版本，更新需替换 vendor 快照并更新 provenance，
  不通过 DMS 插件管理器原地更新。插件偏好仍为可写文件。
- Neovim 已有 init.lua 时不覆盖整个目录。已有 checkout 的变更在 nvim-config
  独立仓库保存；未来更新固定引用不会自动覆盖用户正在编辑的配置。
  首次启动插件仍需要网络，恢复锁定插件可使用 :Lazy restore。
- 这个屏幕模式是当前 Aurora 硬件的快照；迁移到其他屏幕时应修改 outputs.kdl。
- 当前本机仍有旧的 DMS 95-tray-focus.conf 覆盖。切换到 Nix 管理的补丁之前，
  按 docs/niri-tray-focus.md 备份移走它，避免旧副本继续覆盖新生成的服务环境。
- 本次保存和推送配置，不执行系统 switch；不改变正在使用的桌面服务。

## 验证

独立测试命令：

```sh
nix build .#checks.x86_64-linux.desktop-state
nix build .#checks.x86_64-linux.codex-cli-layout
```

它验证缺失时恢复设置、启用插件、屏幕和输入法片段，以及重复恢复保留用户修改。
还验证 JSON、Nix/Lua 语法及 vendored 插件与固定的已安装源码一致。
完整系统构建和从零恢复演练应另外执行；不能把模块求值、脚本构建或当前旧系统运行
等同于完整恢复验证。

本次实际验证结果：

- 完整 NixOS toplevel derivation 求值通过。
- desktop-state 和 codex-cli-layout 两个 Nix 检查构建通过。
- DMS 初始化、完整 Neovim 初始化、VS Code 启动包装器构建通过（含 shellcheck）。
- Neovim 新增 Lua 模块使用不加载用户配置/状态的 headless 语法检查通过。
- quickCapture vendor 的 127 个文件与本机上游固定提交逐字节一致。
- 本机现有官方 CLI 运行 --version 返回 0.162.1；新包安装布局检查使用小型夹具，
  不等于下载并运行了官方 117 MB 发布包。
- 托盘补丁界面的完整构建此前因 GitHub TLS 中断获取 DMS 源码失败，完整系统
  build/switch 和从零安装恢复尚未完成。本次没有以测试夹具代替真实系统验收。
