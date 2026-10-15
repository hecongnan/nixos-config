# 我的 NixOS 配置仓库

本仓库保存系统配置、声明的软件和固定配置文件。个人资料与凭据由单独的加密备份保存。

## 日常使用

```bash
cd ~/src/aurora-nixos
# 修改 Niri 快捷键
nvim assets/niri.kdl
# 查看变更
 git diff
# 先构建，确认成功后再应用
nixos-rebuild build --flake .#aurora
sudo nixos-rebuild switch --flake .#aurora
# 保存本次修改；先检查 git status 和 diff，不要加入私人文件
 git add assets/niri.kdl
 git commit -m "调整桌面快捷键"
```

图形登录、驱动等变更应按原 README 的说明选择 boot 并重启。

## 文件位置

- flake.nix / flake.lock：入口和锁定的依赖，一起提交。
- hosts/aurora/：此机器的硬件、磁盘、主机设置。
- modules/：系统与 Home Manager 配置。
- assets/：固定配置模板，包括 Niri 配置。
- oseasy-video-nixos/：主机直接引用的本地模块，必须与本仓库一起保存。
- inventory/：2026-10-15 采集的额外用户软件清单，不含应用数据。
- RESTORE.md：恢复边界和顺序。
- README.md：原部署说明与历史记录，保留以便追溯。

## 软件清单的范围

系统和 Home Manager 已声明的软件由 flake 重建。另有 22 个用户 profile 条目，
保存在 inventory/user-profile.json；它们尚未迁移进 Home Manager，也没有被移除。
其中 21 项具有 Nixpkgs 属性和可移植的固定版本来源 portableSource。
重建一个对应的软件时，可参考下例，属性与 priority 应从清单中取值：

```bash
NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure --priority 5 \
  github:NixOS/nixpkgs/151fa4e8ddfdd8dd25d945ad94ed54a13de9f6e4#google-chrome
```

nvim-system-tools 是无来源属性的本地构建结果，目前只记录了其工具路径。
完整恢复这一项仍需找到原构建表达式，或保存该 store 路径的运行时闭包；
清单中的 /nix/store 路径只是记录，不能保证在另一台机器直接使用。
本仓库不是完整的离线软件缓存。

## 不放入仓库

文档、浏览器资料、聊天记录、应用数据库、SSH 私钥、API Key、密码、订阅地址、
Wi-Fi 凭据和解密密钥均不应以明文提交。
keys/maintenance.pub 是已有授权公钥，不是私钥；使用本配置意味着继续授权该公钥，
改变它会影响维护访问，应明确审查。硬件标识、用户名与部署历史也在仓库中，当前仅在本地保存。

Neovim 的 ~/.config/nvim/init.lua 和 DMS 的界面设置仍是可写本地状态，
不会自动同步回本仓库；需要单独加密备份。

## 保存副本

本地 Git 历史只防止误改，不能抵抗磁盘损坏。确认远端账号和仓库后，再添加私有远端并推送。
目前未配置 remote，也未上传。个人数据加密备份和密钥保管尚未在此步骤部署。
