# Niri 窗口暂存区

通过 Niri IPC 将任意现有窗口暂存到命名工作区 `scratch`，不启动新应用，
窗口的程序和内容保持运行；呼出后会浮动并居中。

本仓库的 `Mod` 是 Super（Win 键）。

| 快捷键 | 操作 |
| --- | --- |
| Super+Shift+反引号 | 收起当前窗口 |
| Super+反引号 | 呼出最近收起的窗口；聚焦后再按则收起 |
| Super+Ctrl+反引号 | 循环呼出下一个窗口 |

呼出的窗口失去焦点时，切换快捷键先重新聚焦它，再按一次才收起。
支持跨显示器呼出。`scratch` 是普通工作区，会出现在 Overview、工作区列表和
上下切换中，并影响数字工作区索引。误进暂存区时，先切回普通工作区再呼出，
也可使用原有窗口移动操作直接移出。

将当前聚焦的窗口移出暂存管理：

```bash
python3 ~/.config/niri/scratchpad.py release
```

窗口保持当前位置及浮动状态，Super+Shift+V 可切回平铺。
状态保存在 `$XDG_RUNTIME_DIR/niri-scratchpad-*.json`，按 Niri socket 区分会话，
不依赖后台守护进程。丢失状态后仅从暂存工作区恢复成员；退出 Niri 后不保留。

Home Manager 通过 `home/aurora/scratchpad.nix` 部署脚本和 `scratchpad.kdl`，
`assets/niri.kdl` 加载该片段。按仓库正常 build/switch 流程应用配置后生效。

验证：`python3 tests/test-scratchpad.py`；Flake 检查项：
`nix build .#checks.x86_64-linux.scratchpad --no-write-lock-file`。
