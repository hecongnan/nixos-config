# niri 托盘聚焦修复

本仓库通过 flake input `dms-tray-focus` 引用独立公开补丁：
https://github.com/hecongnan/dms-niri-tray-focus

当前固定提交：`28bc757b2a2885b5cf99a1bcccd25caa6c1f8636`。
源码和安装器由独立仓库维护，NixOS 配置自动获取脚本和补丁，无需手工克隆或运行安装器。

`home/aurora/desktop.nix` 从当前 `pkgs.dms-shell.src` 复制完整界面及其
DankCommon 子模块，在构建阶段应用补丁，生成仅供 DMS 使用的界面副本。
脚本所需的 Python、niri、busctl 由 Nix 包装器提供；用户服务设置
DMS_SHELL_DIR 和 DMS_TRAY_FOCUS_HELPER，使重启和系统恢复后自动加载。
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
systemctl --user show dms.service -p Environment
systemctl --user is-active dms.service
```

DMS_SHELL_DIR、DMS_TRAY_FOCUS_HELPER 应指向 /nix/store 中的构建结果。

## 更新补丁

修改 flake.nix 中固定的独立补丁提交，更新 flake.lock，先构建验证再部署。

## 验证

Nix 语法解析、完整 NixOS 系统 derivation 求值和聚焦脚本包装器构建已通过。
补丁界面构建需要下载 DMS 软件包的完整源码与子模块；该源码获取已因 GitHub TLS 中断失败，
尚未宣称完整界面构建或系统切换成功。现有本机修复保持原来的加载方式，
本次提交只更新仓库，不执行系统切换。
