# DUX 鼠标电量

在 [Dux Modular Shell](https://duxlabs.dev/docs/dms/plugins-overview) 的栏上显示鼠标图标和电量百分比。电量通过 UPower 自动更新。暂时读不到电量时显示 `—`。

## 安装

需要 DUX 2.0 或更新版本，以及能识别鼠标电量的 UPower。已在 Arch Linux、Niri 和罗技 PRO X Wireless 上验证。

```bash
git clone https://github.com/hecongnan/dux-mouse-battery.git "${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugins/mouseBattery"
```

1. 打开 DUX 设置中的 **Plugins（插件）**，点击 **Scan（扫描）**，启用 **鼠标电量**。
2. 找到主栏的组件布局，点击 **Add widget（添加组件）**，选择 **鼠标电量**。可以把它放在电脑电池图标旁边。

如果想把电量显示在壁纸上，也可以从 **Desktop Widgets（桌面组件）** 添加 **鼠标电量**。只想在栏上显示时，完成上述两步即可。

若 DUX 栏显示 `—`，可以运行 `upower -d`，查看系统是否已识别鼠标及其电量。
