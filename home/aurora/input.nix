{ config, lib, pkgs, ... }:
let
  rime = pkgs.fcitx5-rime.override { rimeDataPkgs = [ pkgs.rime-ice ]; };
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = [ rime pkgs.fcitx5-gtk pkgs.qt6Packages.fcitx5-configtool ];
    };
  };
  systemd.user.sessionVariables.QT_IM_MODULE = "fcitx";
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=rime
    [Groups/0/Items/0]
    Name=keyboard-us
    [Groups/0/Items/1]
    Name=rime
    [GroupOrder]
    0=Default
  '';
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Fcitx 5
    Hidden=true
  '';
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    text = ''
      patch:
        __include: rime_ice_suggestion:/
        schema_list:
          - schema: rime_ice
    '';
    onChange = ''
      # Drop deployment output only; learned words and user dictionaries remain.
      run ${pkgs.coreutils}/bin/rm -rf ${lib.escapeShellArg "${config.xdg.dataHome}/fcitx5/rime/build"}
    '';
  };
  # Store files have fixed mtimes. Redeploy when the packaged schema changes.
  xdg.dataFile."fcitx5/rime/.schema-package" = {
    text = "${rime}";
    onChange = ''
      run ${pkgs.coreutils}/bin/rm -rf ${lib.escapeShellArg "${config.xdg.dataHome}/fcitx5/rime/build"}
    '';
  };
  systemd.user.services.fcitx5-daemon.Unit = {
    Conflicts = [ "app-org.fcitx.Fcitx5@autostart.service" ];
    X-Restart-Triggers = [ "${rime}" ];
  };
}
