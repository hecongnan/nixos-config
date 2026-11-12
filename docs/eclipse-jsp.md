# Eclipse 与 JSP

`home/aurora/eclipse.nix` 通过 Home Manager 安装 Eclipse 企业版和 Tomcat 10，并提供 `eclipse-jsp` 命令及应用菜单启动项。启动项使用现有的 `~/Documents/Codex/2026-11-12/xia/outputs/eclipse-workspace` 工作区和同级 `eclipse-config` 配置目录。项目、浏览器设置和 Eclipse 偏好仍由 Eclipse 管理；这些目录是用户数据，应在清理 Codex 输出或迁移机器前备份。

Home Manager 激活后，Tomcat 的稳定路径为 `~/.local/share/eclipse/tomcat`，它指向当前配置锁定的 Tomcat 包。已有工作区原先指向某个具体的 `/nix/store/...-apache-tomcat-10.1.57` 路径。首次激活后，在 Eclipse 中打开 **Window → Preferences → Server → Runtime Environments**，编辑 `Apache Tomcat v10.1`，把安装目录改为 `/home/aurora/.local/share/eclipse/tomcat`，然后点击 **Apply and Close**。这样后续更新 Tomcat 时无需修改工作区里的安装目录。升级后如提示服务器配置与运行时不一致，检查 Servers 视图中的 Tomcat 配置。

确认新的 Home Manager 代际已生效、工作区和服务器正常后，才考虑移除之前使用 `nix profile` 单独安装的 `eclipse-jee` 和 `tomcat10`。不要删除工作区或配置目录。
