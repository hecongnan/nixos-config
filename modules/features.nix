{ config, lib, pkgs, ... }:
let
  cfg = config.my.features;
in
{
  options.my.features = lib.genAttrs
    [ "bluetooth" "graphicalBoot" "computerUse" "nixLd" "appimage" "phoneIntegration" "direnv" "terminalTools" ]
    (name: { enable = lib.mkEnableOption name; });

  config = {
    hardware.bluetooth = lib.mkIf cfg.bluetooth.enable {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = cfg.bluetooth.enable;
    programs.nix-ld.enable = cfg.nixLd.enable;
    programs.appimage = {
      enable = cfg.appimage.enable;
      binfmt = cfg.appimage.enable;
    };
    programs.direnv = lib.mkIf cfg.direnv.enable {
      enable = true;
      nix-direnv.enable = true;
    };
    programs.kdeconnect = lib.mkIf cfg.phoneIntegration.enable {
      enable = true;
      package = pkgs.valent;
    };
    services.avahi = lib.mkIf cfg.phoneIntegration.enable {
      enable = true;
      nssmdns4 = true;
      publish = { enable = true; userServices = true; };
    };
  };
}
