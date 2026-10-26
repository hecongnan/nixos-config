# niri 托盘聚焦修复

本仓库通过 flake input `dms-tray-focus` 引用独立公开补丁：
https://github.com/hecongnan/dms-niri-tray-focus

当前固定提交：`7d86167f9ffb5183c4f367a31913f60969c5df4e`。
源码和安装器由独立仓库维护，NixOS 配置自动获取脚本和补丁，无需手工克隆或运行安装器。

`home/aurora/desktop.nix` 从锁定的 `inputs.dms` 复制 1.6.2 界面，并从该输入锁定的
`dank-qml-common` 补齐 DankCommon；构建时应用托盘补丁。CLI 也使用相同的锁定 DMS 版本。
脚本所需的 Python、niri、busctl 由 Nix 包装器提供。用户服务除了设置
DMS_SHELL_DIR 和 DMS_TRAY_FOCUS_HELPER，还必须显式传入 `--config` 选择补丁界面：
软件包包装器自带的 `-c` 参数会优先于环境变量，只设置环境变量无法保证加载补丁。
补丁目前仅适配 DMS 1.6.2，升级版本会在构建时拒绝继续，需要先适配。

## 部署与恢复

按本仓库正常的 `nixos-rebuild switch --flake .#aurora` 流程部署即可。
恢复到新系统时无需另外下载独立补丁或手动执行安装器。

若本机已有之前手动安装的服务覆盖，应在部署前备份并移走相关的
`~/.config/systemd/user/dms.service.d/95-tray-focus.conf` 或
`99-niri-tray-focus.conf`，以免它们覆盖 Nix 生成的环境变量。
保留 `90-icon-theme.conf` 等无关配置。旧界面副本可以在新配置成功启动后再清理。

验证 DMS 服务实际环境：

```sh
systemctl --user show dms.service -p Environment -p ExecStart
systemctl --user is-active dms.service
```

DMS_SHELL_DIR、DMS_TRAY_FOCUS_HELPER 应指向 /nix/store 中的构建结果。
ExecStart 的 `--config` 也应指向同一补丁界面。还需检查本次启动日志中的
`Launching config` 路径；环境变量存在本身不足以证明补丁已加载。

## 更新补丁

修改 flake.nix 中固定的独立补丁提交，更新 flake.lock，先构建验证再部署。

## 验证

2026-10-26 已完成完整系统构建及切换，并核对当前进程实际加载补丁版界面。
托盘脚本 6 项回归测试通过；微信、FlClash、Chromium 托盘能够匹配已有窗口。
详细结果和交互测试边界见 [补丁配置审查](patch-audit-2026-10-26.md)。

可运行只读检查：`python3 scripts/audit-patches.py`。

## FlClash 隐藏窗口恢复（2026-10-23）

固定补丁版本现在额外支持 FlClash 的 Ayatana 托盘：该托盘没有 Activate 接口，
窗口隐藏后不在 niri 窗口列表中。脚本会查找明确的“显示 / Show / 顯示”菜单项，
调用后等待窗口出现再聚焦，不触发代理模式、暂停或退出操作。
本机已验证“显示”菜单恢复窗口和脚本聚焦；独立仓库 6 项回归测试通过。
2026-10-26 已切换到 Nix 管理的脚本，旧的本地服务覆盖已备份停用。
