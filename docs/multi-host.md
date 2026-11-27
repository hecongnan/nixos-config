# 多主机维护

| 设备 | Flake 入口 | 主机模块 |
| --- | --- | --- |
| 教室电脑 | `.#aurora` | `hosts/aurora/default.nix` |
| 笔记本 | `.#laptop` | `hosts/laptop/default.nix` |
| 安装预览虚拟机 | `.#aurora-preview` | `tests/preview.nix` |

Flake 入口用于选择构建配置。笔记本的系统主机名由本机模块设置。

## 配置放在哪里

| 位置 | 用途 |
| --- | --- |
| `flake.nix`、`flake.lock` | 声明入口与依赖，锁定依赖版本。 |
| `hosts/<机器>/default.nix` | 选择公共模块、可选服务和机器专属模块。 |
| `hosts/laptop/local/` | 由 Git 忽略，用于笔记本自己的硬件、挂载、引导和主机名。 |
| `modules/nixos/` | 共享基础系统、网络、账号与 SSH、桌面和 Home Manager。Docker 由每个需要的主机单独导入。 |
| `home/aurora/` | 两台机器共用的 Fish、Neovim、Niri、DMS、输入法和用户应用。 |
| `assets/`、`pkgs/` | 配置模板、脚本和自定义软件包。 |
| `tests/`、`docs/` | 检查、安装预览和维护说明。 |

添加用户软件时编辑 `home/aurora/packages.nix`。新增共享服务时，在 `modules/nixos/` 编写模块，并由公共入口或需要它的主机导入。单机的驱动、磁盘、引导和接口放在其主机目录。

## 在笔记本上构建

保留 `hosts/laptop/local/` 下这三个由本机提供的文件，并单独做备份。

- `hardware-configuration.nix` 记录真实硬件和文件系统挂载。换机时以目标机的硬件扫描和挂载为准。
- `boot.nix` 记录实际引导器及 EFI 挂载。首次应用前，备份并核对当前菜单和任何手动安装的主题。
- `machine.nix` 设置本机的 `my.machine.hostName`。登录凭据单独配置，Git 忽略的 Nix 文件也只用于可公开读取的系统设置。

在仓库根目录用 `path:` 方式构建，让 Nix 可以读到 Git 忽略的本机模块。

```bash
nix eval --raw "path:$PWD#nixosConfigurations.laptop.config.networking.hostName"
nixos-rebuild build --flake "path:$PWD#laptop" --no-write-lock-file
```

只有 Git 源码的副本可以列出 `.#laptop` 入口。构建前需准备上述本机文件。教室电脑继续使用 `nixos-rebuild build --flake .#aurora`。
