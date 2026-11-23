# niri 托盘聚焦修复

本仓库通过 flake input `dms-tray-focus` 引用独立公开补丁：
https://github.com/hecongnan/dms-niri-tray-focus

当前固定提交：`7d86167f9ffb5183c4f367a31913f60969c5df4e`。
该提交提供 Python 聚焦脚本和原始补丁。

DMS 2.1.2 将托盘组件移到 `Modules/DBar/Widgets`。`home/aurora/dms-tray-focus.patch`
把原有聚焦逻辑移到 `TrayMenuManager`，覆盖栏内、展开区和溢出菜单中的四条点击路径。
在 niri 上优先调用脚本聚焦已有窗口，脚本失败时回退到原生托盘激活。
FlClash 隐藏窗口的恢复继续使用锁定的 Python 脚本。

`home/aurora/desktop.nix` 对锁定的 DMS 包直接应用新版补丁，CLI 和 QML 因此使用同一版本。
补丁以零模糊匹配应用，若上游修改了相关代码，构建会报错。
用户服务显式传入 `--config` 并通过 `DMS_TRAY_FOCUS_HELPER` 传入脚本路径。

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

升级 DMS 时检查本地 QML 补丁是否仍覆盖全部托盘激活路径。更新 Python 脚本时修改 flake.nix 中固定的独立补丁提交并更新 flake.lock。先构建验证再部署。

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
