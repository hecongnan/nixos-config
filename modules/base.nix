{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.my.machine;
  maintenanceKey = lib.removeSuffix "\n" (builtins.readFile ../keys/maintenance.pub);
in
{
  options.my.machine = {
    username = lib.mkOption { type = lib.types.str; default = "aurora"; };
    hostName = lib.mkOption { type = lib.types.str; default = "aurora"; };
    installationReady = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Target hardware and disk layout have been reviewed";
    };
    diskDevice = lib.mkOption { type = lib.types.str; };
  };

  config = {
    assertions = [
      {
        assertion = cfg.installationReady;
        message = "Installation pending: generate target hardware configuration, review disk/boot layout, provide login password, then set my.machine.installationReady.";
      }
      {
        assertion = !(lib.hasInfix "REPLACE" cfg.diskDevice);
        message = "Replace my.machine.diskDevice with the reviewed target disk.";
      }
    ];

    networking.hostName = cfg.hostName;
    networking.networkmanager.enable = true;
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    time.timeZone = "Asia/Shanghai";
    i18n.defaultLocale = "zh_CN.UTF-8";

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirror.tuna.tsinghua.edu.cn/nix-channels/store" ];
    };
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [ git vim wget ];

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

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      extraSpecialArgs = { inherit inputs; };
      users.${cfg.username} = import ./home;
    };

    # Keep this initial compatibility version when upgrading nixpkgs.
    system.stateVersion = "26.05";
  };
}
