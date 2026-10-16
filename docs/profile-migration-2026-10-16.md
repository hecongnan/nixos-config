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

初始声明化提交 b9f7cd4 只构建并保存配置，当时未执行 switch 或移除旧 profile。
后续激活与清理见下方记录。

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

## 后续授权的激活与 profile 清理

用户随后授权执行 switch、清理旧 profile 和私有 GitHub 推送。
sudo 需要本机认证，用户在自己的终端完成了切换；核验运行系统已指向上述构建产物。
Home Manager 服务 Result=success，系统和用户均无失败单元。
实际 `/etc/profiles/per-user/aurora/bin` 中的 250 个原 profile 命令来源全部一致。

保存旧 profile manifest 和代际信息后，仅移除了已声明化的 22 个重复条目。
默认用户 profile 当前为空，旧第 12 代保留，未执行 GC 或删除任何代际。
清理后再次核验上述 250 个命令仍全部可用且来源不变。

如需恢复本机原 profile，可使用 `nix profile rollback --to 12`；
这是本次机器的历史代际编号，不适用于其他机器，也不回滚系统或应用数据。
图形应用启动、LazyVim 实际使用等仍需用户日常验收。
