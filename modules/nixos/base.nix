{ config, lib, pkgs, ... }:
let
  cfg = config.my.machine;
in
{
  imports = [ ./networking.nix ./users.nix ./home-manager.nix ];

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

    time.timeZone = "Asia/Shanghai";
    i18n.defaultLocale = "zh_CN.UTF-8";

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirror.tuna.tsinghua.edu.cn/nix-channels/store" ];
    };
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [ git vim wget ];

    # Keep this initial compatibility version when upgrading nixpkgs.
    system.stateVersion = "26.05";
  };
}
