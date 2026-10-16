{ config, lib, pkgs, ... }:
let
  package = pkgs.callPackage ../../pkgs/flclash { };
  initialPreferences = (pkgs.formats.json { }).generate "flclash-initial-preferences.json" {
    "flutter.config" = builtins.toJSON {
      appSettingProps = {
        silentLaunch = true;
        autoLaunch = false;
        autoCheckUpdate = false;
      };
    };
  };
  initialize = pkgs.writeShellApplication {
    name = "initialize-aurora-flclash";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      directory=${lib.escapeShellArg "${config.xdg.dataHome}/com.follow.clash"}
      install -d -m 700 "$directory"
      if [ ! -e "$directory/shared_preferences.json" ]; then
        install -m 600 ${initialPreferences} "$directory/shared_preferences.json"
      fi
    '';
  };
in
{
  home.packages = [ package ];
  home.activation.initializeFlclash = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe initialize}
  '';
  # Let Home Manager own startup; leave the app's autoLaunch setting disabled.
  systemd.user.services.flclash = {
    Unit = {
      Description = "FlClash desktop client";
      After = [ "graphical-session.target" "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = lib.getExe initialize;
      ExecStart = "${package}/bin/FlClash";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
