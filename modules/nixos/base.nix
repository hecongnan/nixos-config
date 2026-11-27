{ lib, pkgs, ... }:
{
  imports = [ ./networking.nix ./users.nix ./home-manager.nix ];

  options.my.machine = {
    username = lib.mkOption { type = lib.types.str; default = "aurora"; };
    hostName = lib.mkOption { type = lib.types.str; default = "aurora"; };
  };

  config = {
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
