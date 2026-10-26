# 补丁配置审查：2026-10-26

范围：本仓库的自定义 Nix 配置、软件包，以及锁定的 `computer-use` 和
`dms-tray-focus` 输入引入的补丁。区分源码声明、构建产物和当前运行状态。
本次未更新 flake 输入，未重启桌面或机器，未修改用户文档。

## 结论

首次审查时系统与 `result` 均为
`/nix/store/5xhhihxlm58xrf8l0w3wd8j3iv8g8zvg-nixos-system-aurora-26.11.20261023.3ec6363`。

用户随后完成 switch。提交前只读复核确认：

- `/run/current-system` 为 `/nix/store/z5idvlbiidjy4xyr0yyzdqypyq5842r1-nixos-system-aurora-26.11.20261023.3ec6363`，与当前仓库配置求值结果完全一致。
- 当前 niri 已运行 `32p2gysxw89drqp0vv0jy1pib6k04dx7-niri-26.04-unstable-2026-10-13`，包含 Smithay 输入法键盘映射修复。
- `/run/booted-system` 与 `result` 仍指向上述 `5xhh…` 系统，但该代与当前系统的 kernel、initrd 均指向相同产物。脚本将此记录为 NOTE，不据此要求重启；启动画面的目视验证仍未执行。

## 逐项结果

| 项目 | 核验依据 | 结果与限制 |
| --- | --- | --- |
| niri 平铺窗口坐标 | 旧、新 niri 派生均含 `niri-ipc-tiled-window-position.patch`；提交前实时 IPC 的 6 个平铺窗口均返回 `tile_pos_in_workspace_view` | 当前生效 |
| niri Agent 输入 | 旧、新派生均含 `niri-agent-input.patch`；通过真实 CUA 对非聚焦 kitty 输入英文和中文，然后清空，未按回车或执行命令 | 当前生效；聚焦目标拒绝 Agent 输入属于补丁的预期限制 |
| Smithay 输入法键盘映射 | 新 niri 的 `postPatch` 明确应用 `smithay-input-method-keymap.patch`；旧进程派生不含该修复 | 已构建；提交前确认当前会话已运行新版 niri |
| Codex computer-use 后端 | 安装的后端二进制与锁定定制后端逐文件 SHA-256 相同；见下文补丁清单 | 定制二进制保留 |
| Codex JS 适配与浏览器状态 | `native-client`、`native-service`、`native-backend-service`、`native-protocol` 四文件与锁定定制后端相同；公共浏览器状态修复存在 | 当前生效；删除的是重复打补丁步骤 |
| computer-use 运行链路 | 真实 CUA 窗口枚举、Codex AT-SPI、原生窗口坐标、窗口截图、后台英文/中文输入成功；doctor 的 readiness 无 blockers | 已完成上述实测；未对拖拽、所有滚动场景逐一交互测试 |
| DMS 托盘聚焦 | 实际服务参数显式 `--config` 指向 Nix store 补丁界面；日志确认加载该 `shell.qml`；四处 QML 激活入口均已替换；helper 指向 store | 补丁版已实际加载；微信、FlClash、Chromium 托盘均能匹配已有窗口。未逐项模拟真实托盘鼠标点击 |
| FlClash 原生库与 TUN helper | `flclash-loader` 检查通过；Core SHA-256 与 helper 的 manifest 相同；系统 helper active | 包修复保留；未切换代理/TUN 开关或测试外网流量 |
| 窗口暂存区 | 已部署脚本和 KDL；主配置包含片段；`niri validate` 成功；现有 scratchpad 检查通过 | 已部署，自动化回归通过；未暂存用户现有窗口 |
| Fcitx5 / 雾凇 | 服务 active；`default.custom.yaml` 指定 `rime_ice`；已生成的 `build/default.yaml` 与 schema 对应 | 当前已部署启用；中文后台输入测试不等于完整输入法候选框测试 |
| 60 Hz 屏幕 EDID | 内核参数包含覆盖路径；当前 `/sys/class/drm/*-eDP-1/edid` 与仓库二进制一致 | 当前生效 |
| Plymouth 与 greetd 交接 | 构建产物和 greetd 单元保留定制配置；`dms-greeter` 用户仍存在，等待脚本用户名与新版模块一致 | 新启动过程需重启后目视验证；已删除的 verbose 选项本身无效 |
| Boreal GRUB | 配置保留主题与渲染脚本；最近 switch 终端输出 `Boreal: rendered 6 actual GRUB entries`，切换成功 | 安装步骤成功；未重启目视验证引导菜单 |
| Codex CLI | 真实入口报告 `0.162.1`；打包布局检查通过 | 自定义入口保留；布局测试本身使用小型 fixture，不冒充完整功能测试 |
| VS Code X11 启动器 | 实际 `code-x11` 包含清除 `NIXOS_OZONE_WL`、`--ozone-platform=x11 --disable-gpu` | 包装器保留；未打开额外 VS Code 实例 |
| Neovim 与工具环境 | Nix 配置保留 sideloadInitLua、provider 与优先级定制、完整工具环境；安装入口存在 | 配置/产物核对，未运行插件更新或修改可写配置 |

## Codex 后端补丁清单

锁定 `computer-use` 输入的 `packages/codex-desktop.nix` 将以下补丁应用到后端源码：

1. `codex-niri-window-screenshot.patch`
2. `codex-niri-window-coordinates.patch`
3. `codex-linux-native-drag.patch`
4. `codex-linux-drag-interpolation.patch`
5. `codex-niri-scroll-unicode.patch`
6. `codex-niri-agent-input.patch`

JS 适配额外应用 `codex-linux-native-launch.patch`，当前客户端还含浏览器状态兼容修复。
已核对最终桌面包中的原生二进制和四个 JS 文件与这一锁定后端一致。
这证明实际使用定制产物，不代表每项边界行为都已做交互回归。

## 已执行检查

- `checks.x86_64-linux.scratchpad`：通过。
- `checks.x86_64-linux.desktop-state`：通过。
- `checks.x86_64-linux.flclash-loader`：通过。
- `checks.x86_64-linux.codex-cli-layout`：通过。
- 锁定托盘补丁的 `test_focus.py`：6 项通过。
- 当前配置的 `niri validate`：通过。
- `codex-computer-use doctor`：readiness 所有检查通过、无 blockers；其他桌面环境的探测失败不作为 niri 故障。
- 系统和用户 systemd failed 单元：均为 0。

FlClash 的 AT-SPI 读取曾超过 10 秒，但其窗口枚举、坐标可取得；Codex 与 GTK 编辑器
的 AT-SPI 成功。因此不能把所有应用的辅助功能树支持都标记为通过。

## 重启后的只读复核

```sh
cd /home/aurora/src/aurora-nixos
python3 scripts/audit-patches.py
```

该脚本不会改变配置、焦点、窗口或输入内容。退出码 0 表示脚本覆盖的检查通过，
1 表示检查失败，2 表示仍有重新登录或重启待办。它不替代上表中的交互测试与启动画面目视验证。

首次审查时脚本结果：7 项 PASS，0 项 FAIL，2 项 PENDING。
提交前复核结果：8 项 PASS，0 项 FAIL，0 项 PENDING，1 项 NOTE（开机代数不同，但 kernel 与 initrd 相同）；niri 进程版本检查已通过。
