{ config, lib, pkgs, ... }:
let
  workspace = "${config.home.homeDirectory}/Documents/Codex/2026-11-12/xia/outputs/eclipse-workspace";
  configuration = "${config.home.homeDirectory}/Documents/Codex/2026-11-12/xia/outputs/eclipse-config";
  launcher = pkgs.writeShellApplication {
    name = "eclipse-jsp";
    text = ''
      exec ${pkgs.eclipses.eclipse-jee}/bin/eclipse \
        -configuration ${lib.escapeShellArg configuration} \
        -data ${lib.escapeShellArg workspace} "$@"
    '';
  };
in
{
  # Keep workspace and Eclipse preferences writable and owned by Eclipse.
  home.packages = [ pkgs.eclipses.eclipse-jee pkgs.tomcat10 launcher ];
  # A stable path for the runtime configured in Eclipse, even after upgrades.
  xdg.dataFile."eclipse/tomcat".source = pkgs.tomcat10;
  xdg.desktopEntries.Eclipse = {
    name = "Eclipse IDE for Enterprise Java and Web Developers";
    genericName = "Java and Web IDE";
    comment = "Develop Java and JSP applications";
    exec = "${lib.getExe launcher} %F";
    icon = "eclipse";
    terminal = false;
    startupNotify = true;
    categories = [ "Development" "IDE" "Java" ];
    settings.StartupWMClass = "Eclipse";
  };
}
