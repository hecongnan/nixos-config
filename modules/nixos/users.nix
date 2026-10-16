{ config, lib, pkgs, ... }:
let
  cfg = config.my.machine;
  maintenanceKey = lib.removeSuffix "\n" (builtins.readFile ../../keys/maintenance.pub);
in
{
  programs.fish.enable = true;
  users.users.${cfg.username} = {
    isNormalUser = true;
    uid = 1000;
    group = cfg.username;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ maintenanceKey ];
    # Supply this file through nixos-anywhere --extra-files; never in the store.
    hashedPasswordFile = "/var/lib/private/aurora-password.hash";
  };
  users.groups.${cfg.username}.gid = 1000;
  users.users.root.openssh.authorizedKeys.keys = [ maintenanceKey ];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
