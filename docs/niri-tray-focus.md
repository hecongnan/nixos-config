# niri 托盘点击聚焦

DMS 的托盘 Activate 接口不一定能让 niri 聚焦已有窗口。桌面模块现在从
flake.lock 锁定的 DMS 源码构建带补丁的界面，通过 systemd 用户服务的
DMS_SHELL_DIR、DMS_TRAY_FOCUS_HELPER 加载，不需要复制整个 DMS 到仓库。

- 左键点击普通应用图标时先查找 niri 中 app_id 与托盘 Id 完全匹配的窗口。
- 对 Chromium 等通用托盘 Id，通过会话 D-Bus 查询托盘所属进程，匹配窗口 PID。
- 有多个匹配窗口时选择最近聚焦的窗口，支持跨工作区聚焦。
- 没有匹配窗口或查询失败时继续调用应用原来的 Activate 接口。
- 只提供菜单的图标、右键菜单及拖动排序保持原有行为。

文件：assets/dms/focus-tray-window.py、assets/dms/tray-focus.patch、
home/aurora/desktop.nix。脚本依赖由 Nix 包装器提供。

## 部署

按仓库现有流程运行 nixos-rebuild switch。升级 DMS 时需要检查补丁能否应用；
上下文不匹配会在构建时失败，避免静默丢失修复。

若机器之前使用本次修复的临时本地覆盖，应先备份并移走
~/.config/systemd/user/dms.service.d/95-tray-focus.conf，再部署新配置。
该旧文件会覆盖服务中的新环境变量。切换成功后可移走旧的
~/.local/share/dms-tray-focus 界面副本。

## 验证

本机已验证 wechat app_id 匹配、ChatGPT 通用 Chromium 托盘的 D-Bus PID
匹配，以及多窗口最近聚焦顺序、无匹配回退和桌面栏加载。

仓库验证：Nix 语法解析、针对锁定 DMS 源码的补丁应用和四处调用替换、
窗口匹配检查均通过。完整 Nix 构建在获取锁定的 dank-qml-common 依赖时
遇到网络超时，尚未完成；部署前应在网络正常的环境中完成构建。

## 给其他用户使用

`assets/dms/` 现在也是独立补丁包，详见该目录的 README.md。
包含 Python 安装器和可恢复回滚，不依赖本仓库的 NixOS 主机配置。
