# 2026-10-16 用户 profile 软件声明化

## 变更范围

原 profile 的 22 项软件加入 `home/aurora/packages.nix`，由现有 Home Manager 用户入口读取。
沿用当前模块结构，没有另建重复的 home.nix。`flake.nix`、`flake.lock`、stateVersion 和账户设置不变。

21 项直接使用现有锁定 Nixpkgs 中的对应属性：

```text
btop fastfetch ffmpeg google-chrome gpu-screen-recorder
imagemagick img2pdf libreoffice neovim nodejs
qq scrcpy tesseract vim vlc vscode wechat-uos
wf-recorder wireshark wpsoffice zbar
```

各包现有 meta.priority 与旧 profile 的显式优先级相同，直接保留：
LibreOffice -10，fastfetch/Neovim 4，Tesseract 10，其余 5。
原 profile Neovim 和 HM 包装版原本同为优先级 4，合并时产生 bin/nvim 冲突。
仅将 HM 的 unwrapped 包元数据优先级设为 6，其包装器减 1 后为 5；
原 profile 包仍为 4，保持原命令选择和两个包的原运行内容。
未覆盖实际 LazyVim 配置，也未改变 HM 原有初始化逻辑。

## nvim-system-tools

从现有工具集合的 Nix Store derivation 读取了原 chosenOutputs、顺序和 pathsToLink，
恢复为 `pkgs/nvim-system-tools/default.nix`。包含编译器、语言服务器、调试器、格式化器、
Python/pip/pynvim、Java、Go、Rust 和字体。使用 Nixpkgs 属性，不硬编码 store 路径。

在当前锁下求值得到与原安装完全相同的：

```text
/nix/store/slpa8h79sf966s4znzxa6pjwng7m7y2b-nvim-system-tools.drv
/nix/store/kdmd9nfq460pr6ml28imya4xk6d18ajs-nvim-system-tools
```

## 核对与应用边界

逐项对比旧 profile manifest 与 HM home.path derivation 的 chosenOutputs：
全部 22 项的软件输出集合和优先级一致。原 inventory 清单保留为历史核对记录。
软件声明变化会生成新的 HM 环境和系统产物，不能要求系统路径与目录迁移前相同。

本次只构建、保存 Git 提交；不执行 switch、不移除旧 profile、不修改应用数据、不推送。
因而运行系统与旧 profile 暂时保持原状，声明式接管需要后续激活验收。

后续验收应核对 `nvim`、Python、编译器等命令来源与桌面应用，
确认通过后再决定移除旧 profile 重复项。数据备份仍按 RESTORE.md 单独处理。
原 installation 测试的 EFI 断言问题与本次软件声明化无关，仍单独记录。

## 最终验证结果

`nixos-rebuild build --flake .#aurora --offline --no-write-lock-file` 通过，产物为：

```text
/nix/store/bhgkwahbyczxcji205w24agyy9988540-nixos-system-aurora-26.11.20261006.151fa4e
```

构建后逐个对比原 profile 的 250 个命令：新 HM 环境均解析到同一原始可执行文件。
再次核对全部 22 项的输出集合和优先级均匹配，原 profile manifest 未变化。
构建期所需 XML 工具已从原系统配置的可信缓存补齐，未更改依赖锁或缓存设置。
这些检查验证安装环境与命令来源；尚未执行图形应用启动、LazyVim 使用或系统激活验收。
