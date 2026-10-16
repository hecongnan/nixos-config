# 2026-10-16 配置目录迁移

## 范围与基线

在原 checkout `~/src/aurora-nixos` 上整理，没有另建一套未被使用的配置。
迁移起点为 `4be7c06`，此前已保存原有三份文档修改。
本次不更新依赖、不激活系统、不创建远程仓库或推送。

## 文件对应

| 原位置或内容 | 新位置 |
| --- | --- |
| 主机入口中的 Docker 声明 | `modules/nixos/docker.nix` |
| 主机入口中的 GRUB 声明 | `hosts/aurora/boot.nix` |
| `modules/` 下的系统模块 | `modules/nixos/` 中对应文件 |
| `modules/base.nix` | `modules/nixos/base.nix`，并提取 networking/users/home-manager |
| `modules/home/` | `home/aurora/` |
| 用户入口中的软件列表 | `home/aurora/packages.nix`，由入口 import 读取 |
| 原 classroom 示例中的本机设置 | `hosts/aurora/classroom.nix`；示例与通用实现保留 |
| 原完整 README | `docs/deployment-history.md`；根 README 改为当前维护入口 |

## 配置迁移提交

```text
e1253de refactor: extract Docker system module
f9c3563 refactor: isolate Aurora boot configuration
052f443 refactor: group system modules under modules/nixos
bb6cdf3 refactor: separate base networking users and Home Manager wiring
c51121e refactor: organize Aurora Home Manager configuration
a0aefd2 refactor: keep classroom settings with Aurora host
```

每阶段展示 Git diff、新文件先跟踪，再执行：

```bash
nixos-rebuild build --flake /home/aurora/src/aurora-nixos#aurora --offline --no-write-lock-file
```

构建输出链接位于本次工作目录，不向原仓库添加 result 文件。
各配置迁移阶段最终均得到：

```text
/nix/store/vyynh7s95ab97148vk1qhz4sk1rasi90-nixos-system-aurora-26.11.20261006.151fa4e
```

它与运行及已启动系统一致。迁移中发现拆分模块会改变列表合并顺序：
Docker 保留原先的导入位置；用户软件列表保留在原用户入口声明，仅提取列表表达式。
一次出现额外重建计划的用户配置构建已中止，之后恢复原合并顺序并重新 build 通过。
没有为通过构建而更新依赖、调整账户或更改硬件设置。

## 保留事项

- `flake.nix`、`flake.lock`、两个 stateVersion 均保持原值。
- 硬件、磁盘、GRUB、网络、UID/GID、SSH 授权及密码文件引用保持原值。
- 未执行 switch、boot、重启、格式化、GC 或代际清理。
- 三份历史平台副本、整盘预览模块、测试和安装工具保留。
- 22 项额外 profile 软件、真实 LazyVim 和应用数据仍需独立声明化或备份。
- 原 installation 检查的 GRUB EFI 断言冲突未在本次结构迁移中修改。
- Git 历史及配置仍含内网地址与设备标识；发布前需审核。不存在远端或推送。

## 回退

每个配置阶段是独立提交，可按实际需要使用 Git revert 撤销，再 build 验证。
不要在存在未提交工作时强制重置。由于未激活配置，本次不需要系统回滚。
用户文件与数据库不由 Git 或系统代际自动恢复。
