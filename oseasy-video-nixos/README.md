# NixOS 课堂视频配置包

包含笔记本播放配置、可选学生机中继配置、Python 运行脚本和部署说明。
请保留完整目录结构，不要只复制 `.nix` 文件。

## 从 ZIP 安装

在 NixOS 上解压到 `/etc/nixos`：

```bash
sudo unzip oseasy-video-nixos.zip -d /etc/nixos
```

修改 `/etc/nixos/oseasy-video-nixos/nixos/classroom.nix`，将 `interface`
设为笔记本实际网卡名称，保留或修改学生机 IP `10.115.3.82`。

在 `/etc/nixos/configuration.nix` 已有的 `imports` 列表中加入：

```nix
./oseasy-video-nixos/nixos/classroom.nix
```

先构建，再应用，最后在普通用户图形桌面终端播放：

```bash
sudo nixos-rebuild build
sudo nixos-rebuild switch
oseasy-play
```

flake 用户沿用自己现有的主机配置和构建方式，并将新文件纳入 Git 索引。
现有 Windows 学生机中继仍需保持运行。

完整参数、后台服务、可选 NixOS 学生机配置和验证限制见 `nixos/README.md`。
该文档以 TAR 安装目录 `/etc/nixos/oseasy-video` 举例；ZIP 安装时对应目录
是 `/etc/nixos/oseasy-video-nixos`。

当前配置尚未在真实 NixOS 上构建验证；不包含播放器断流自动重连修复。
