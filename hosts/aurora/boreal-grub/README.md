# NixOS · Boreal GRUB 主题

由 `../boot.nix` 导入。1920×1080，左侧半透明菜单，右侧 Nix 雪花背景。

- `default.nix`：主题打包、图形模式、gfxterm 背景及每次安装 GRUB 后的图片生成钩子。
- `render-menu.py`：读取 NixOS 实际生成的 grub.cfg，生成每个启动项的图片和对应 class。
- `theme/`：已渲染素材；`data/`：菜单图标的 SVG 路径。

NixOS 默认的灰底 NixOS 壁纸属于独立的 gfxterm 背景，不由菜单 theme.txt 控制。
因此 `splashImage` 同步指向本主题的完整壁纸，避免选择系统后露出默认灰底。
`desktop.png` 为深蓝色兜底，终端布局为全屏、无边框。

每次正常 NixOS 引导配置重建后，钩子会根据当次真实菜单重新生成图片，
覆盖当前系统、历史代次、子菜单和既有 Windows 启动项。
图片标题可省略过长部分，但不改写真实标题、ID、内核或 chainloader 命令。
若图片生成或语法校验失败，禁用主题回退到原生文字菜单。

本模块目前仅支持单个 GRUB 启动分区，且布局按 1920×1080 设计。
已通过配置求值、GRUB 安装器构建、真实生成菜单语法检查，以及启动命令前后对比。
视觉过渡效果仍需重启验证。

图像菜单方案和 SVG 图标路径来自 ftonneau/grub-evodevo（提交 688ff17）：
https://github.com/ftonneau/grub-evodevo

上游许可 MIT，见 LICENSE。图标来源详见上游 README 的 Credits。
本目录的定制和 NixOS 接入同样以 MIT 许可提供。
