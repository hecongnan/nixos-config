{ config, lib, pkgs, osConfig, ... }:
{
  imports = [ ./desktop.nix ./input.nix ./shell.nix ./flclash.nix ];
  home = {
    username = osConfig.my.machine.username;
    homeDirectory = "/home/${osConfig.my.machine.username}";
    stateVersion = "26.05";
    packages = import ./packages.nix { inherit lib pkgs osConfig; };
  };
  xdg.enable = true;
  xdg.userDirs = { enable = true; createDirectories = true; };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "microsoft-edge.desktop" ];
      "x-scheme-handler/http" = [ "microsoft-edge.desktop" ];
      "x-scheme-handler/https" = [ "microsoft-edge.desktop" ];
      "application/pdf" = [ "org.gnome.Papers.desktop" ];
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      "image/png" = [ "org.gnome.Loupe.desktop" ];
      "image/webp" = [ "org.gnome.Loupe.desktop" ];
    };
  };
  services.udiskie = { enable = true; automount = true; tray = "never"; };
  systemd.user.services.valent = lib.mkIf osConfig.my.features.phoneIntegration.enable {
    Unit = { Description = "Phone integration"; PartOf = [ "graphical-session.target" ]; };
    Service.ExecStart = "${pkgs.valent}/bin/valent --gapplication-service";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
