# NixOS 课堂视频配置

本目录把当前视频链路移植为 NixOS 模块，默认迁移笔记本播放端，学生机可以
继续运行原来的 Windows 中继。可选配置也支持把学生机中继迁移到 NixOS。
不移植 Windows 官方学生端控制、驱动或远程管理功能。

## 文件

- `classroom.nix`：笔记本参数配置，日常修改这个文件。
- `student-relay.nix`：可选的 NixOS 学生机中继配置。
- `module.nix`：NixOS 模块，声明命令、systemd 服务和防火墙规则。
- `package.nix`：用 Nix 提供 Python、psutil 和脚本；播放端另外提供 mpv。
- `relay.py`：按实际网卡名称读取学生机 IPv4，启动原有视频接收器。

必须保留整个配置包的相对目录结构，不要只复制一个 `.nix` 文件。模块会
从上一级目录读取 `play.py`、`laptop_proxy.py` 和 `oseasy_helper/`。
Nix 把运行文件保存到 store；应用配置后，运行不依赖原仓库目录或虚拟环境。

## 1. 安装到 NixOS 笔记本

将 `oseasy-video-nixos.tar.gz` 带到 NixOS，在下载目录运行：

```bash
sudo mkdir -p /etc/nixos/oseasy-video
sudo tar -xzf oseasy-video-nixos.tar.gz -C /etc/nixos/oseasy-video --strip-components=1
```

在 `/etc/nixos/configuration.nix` **已有的** `imports` 列表中加入一项，
保留原有的硬件和其他配置，不要另写第二个 `imports`：

```nix
imports = [
  ./hardware-configuration.nix
  ./oseasy-video/nixos/classroom.nix
];
```

如果使用 flake，把整个 `oseasy-video/` 放在该 flake 的配置目录里，按实际
位置修改 imports；Git 管理的 flake 需要把这些新文件加入 Git 索引，避免
Nix 提示文件不存在。沿用你的原有 nixpkgs 锁定版本和主机定义即可。
此配置使用 `lib.fileset`，建议 NixOS 24.11 或更新版本。

确认网卡名：

```bash
ip -br -4 address
```

修改 `/etc/nixos/oseasy-video/nixos/classroom.nix` 的 `interface`。
NixOS 上不一定叫 `wlan0`，可能是 `wlp2s0`。以下参数集中在这个文件：

```nix
services.oseasyVideo.laptop = {
  enable = true;
  remote = "10.115.3.82";
  remotePort = 17778;
  interface = "wlan0";
  source = null;
  port = 17780;
  background = false;
};
```

`source = null` 表示每次启动读取当前 IPv4，不固定以前的 `10.121.41.139`。
网卡必须已经有 IPv4，且笔记本能够访问学生机的 HTTP 端口。

先构建检查，再切换系统：

```bash
sudo nixos-rebuild build
sudo nixos-rebuild switch
```

flake 用户沿用原有命令，例如 `sudo nixos-rebuild build --flake /etc/nixos#你的主机名`，
成功后执行对应的 `switch`。配置包不会自行执行这些系统修改。

## 2. 日常播放

学生机中继保持运行，教师开启广播后，在图形桌面的普通用户终端执行：

```bash
oseasy-play
```

这相当于已配置参数的 `python3 play.py`：检查学生机、临时启动本地转发器、
自动打开 mpv。默认关闭 mpv 后，本次临时转发器也会关闭。
不需要手动安装 Python、uv、pip 或再启动另一个笔记本脚本。
不要通过 sudo 启动播放器；GUI 需要当前用户的桌面会话。

只检查学生机 HTTP 响应：

```bash
oseasy-play --check
```

检查成功不等于收到教师关键帧。临时覆盖配置也可以：

```bash
oseasy-play --remote 10.115.3.90 --interface wlp2s0 --port 17781
```

## 3. 让本地播放 URL 持续可用

将笔记本配置改为 `background = true`，然后重新构建并应用。
这会启用系统级 `oseasy-laptop.service`，开机启动无界面的转发器；
只有播放器访问时才建立上游视频连接。服务启动失败会每 3 秒重试。

之后可以在普通用户终端直接打开：

```bash
mpv --no-config --ytdl=no --cache=no http://127.0.0.1:17780/live.ts
```

或继续运行 `oseasy-play`，它会复用已有的本地 HTTP 服务，不关闭该后台服务。
手动启动/查看/停止服务：

```bash
sudo systemctl start oseasy-laptop.service
systemctl status oseasy-laptop.service
journalctl -u oseasy-laptop.service -b -f
sudo systemctl stop oseasy-laptop.service
```

`background = false` 时服务仍可手动启动，但不会开机启动。
只要服务关闭，单独打开本地 URL 就可能出现 Connection refused。
启动一个独立的 `laptop_proxy.py` 也会占用同一端口，请避免重复运行。

## 4. 可选：NixOS 学生机中继

如果学生机仍是 Windows，无需做这一节；继续运行原来的学生机脚本。

如果学生机也迁移到 NixOS，安装同一配置包，在**学生机**的配置中导入
`./oseasy-video/nixos/student-relay.nix`，不要把它当成笔记本配置。
修改 `interface` 为学生机接收教师广播的实际网卡，再构建并应用：

```nix
services.oseasyVideo.relay = {
  enable = true;
  teacher = "10.115.4.137";
  interface = "enp3s0";
  localAddress = null;
  udpPort = 7778;
  httpHost = "0.0.0.0";
  httpPort = 17778;
  openFirewall = true;
};
```

`oseasy-relay.service` 随系统启动，从指定网卡加入 `229.1.4.137` 组播，
把重组的 H.264 封装为 MPEG-TS，提供 `/live.ts`。
`openFirewall` 只在指定课堂网卡放行 UDP 7778 和 TCP 17778，不关闭防火墙。
服务以动态非 root 用户运行，没有桌面控制权限。

```bash
systemctl status oseasy-relay.service
journalctl -u oseasy-relay.service -b -f
sudo systemctl restart oseasy-relay.service
```

HTTP 视频服务没有认证或加密；只应在允许共享视频的受信任课堂网络使用，
不要把 17778 暴露到公网。若笔记本从另一块学生机网卡连接，需要另外为
该入口接口制定合适的防火墙规则，默认不会自动放行所有网卡。

`0.0.0.0` 是监听地址，不是发送目标。笔记本仍需访问学生机真实地址，
如 `http://10.115.3.82:17778/live.ts`。如果迁移后学生机 IP 改变，也要修改
笔记本配置的 `remote`。

## 5. 网络和现有局限

- 笔记本入口只绑定 `127.0.0.1`，不需要开放笔记本入站防火墙端口。
- 笔记本只需要能访问学生机 HTTP；学生机必须能收到教师组播。
- 绑定源 IPv4 不是强制绑定出站设备，VPN、代理和路由仍可能影响连接。
- 启动时读取网卡地址；运行过程中换网络或 DHCP 地址变化后，需要重新运行
  `oseasy-play`，或 `sudo systemctl restart oseasy-laptop.service`。
  学生机网卡地址变化后也要重启 `oseasy-relay.service`。
- systemd 重启的是退出的进程，不会为已经断开的播放器连接自动重连。
  原来的 HTTP 断流和 mpv EOF 问题没有在此次移植中改写；仍可能需要重新播放。
- 保留原实现的限制：最多 4 个上游播放器，无音频、无 UDP 丢包重传。
- 收不到组播时还要检查交换机、组播路由和反向路径过滤；不要仅为排障关闭
  整个防火墙。先检查学生机服务日志是否已收到关键帧。

## 6. 验证范围与参考

交付环境没有 Nix/NixOS：已检查 Nix 文件语法和 Python 单元测试，但没有在
真实 NixOS 主机上执行 derivation 构建、模块求值或课堂端到端播放。
部署时请先执行 `nixos-rebuild build`；以目标主机的构建和课堂测试为准。

本次检查：4 个 Nix 文件语法通过；视频、CLI、笔记本转发和新增 NixOS 中继
共 25 项测试通过。全量测试 44/45 通过，未修改的文件接收集成测试在关闭
连接后重绑定端口时报 `Address already in use`，未在此视频移植中改动它。

配置方式依据官方资料：

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual：文件集和软件包构建](https://nixos.org/manual/nixpkgs/stable/)
- [NixOS 官方 Wiki：按接口配置防火墙](https://wiki.nixos.org/wiki/Firewall)
