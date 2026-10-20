{ config, lib, pkgs, ... }:
let
  code = pkgs.writeShellApplication {
    name = "code-x11";
    text = ''
      exec ${pkgs.coreutils}/bin/env -u NIXOS_OZONE_WL \
        ${pkgs.vscode}/bin/code --ozone-platform=x11 --disable-gpu "$@"
    '';
  };
  codex = pkgs.callPackage ../../pkgs/codex-cli { };
in
{
  home.packages = [ code codex ];
  home.file.".local/bin/codex".source = "${codex}/bin/codex";
  xdg.desktopEntries.code = {
    name = "Visual Studio Code";
    genericName = "Text Editor";
    comment = "Code Editing. Redefined.";
    exec = "${lib.getExe code} %F";
    icon = "vscode";
    terminal = false;
    startupNotify = true;
    settings.StartupWMClass = "Code";
    categories = [ "Utility" "TextEditor" "Development" "IDE" ];
    mimeType = [ "application/x-code-workspace" "text/plain" "inode/directory" ];
    actions.new-empty-window = {
      name = "New Empty Window";
      exec = "${lib.getExe code} --new-window %F";
      icon = "vscode";
    };
  };
  xdg.desktopEntries.code-url-handler = {
    name = "Visual Studio Code - URL Handler";
    exec = "${lib.getExe code} --open-url %U";
    icon = "vscode";
    terminal = false;
    noDisplay = true;
    startupNotify = true;
    categories = [ "Utility" "TextEditor" "Development" "IDE" ];
    mimeType = [ "x-scheme-handler/vscode" ];
  };
}
