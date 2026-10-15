{ inputs, config, pkgs, lib, ... }:
{
  imports = [ ../../oseasy-video-nixos/nixos/classroom.nix ] ++ [
    ./machine.nix
    ./features.nix
    ./hardware-configuration.nix
    ./platform.nix
    ./display.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/greeter.nix
    ../../modules/graphical-boot
    ../../modules/computer-use
    ../../modules/features.nix
    ../../modules/flclash.nix
    ../../modules/disk.nix
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = true;
    timeout = lib.mkForce 5;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      configurationLimit = 3;
      timeoutStyle = lib.mkForce "menu";
      extraEntries = ''
        menuentry "Windows (Microsoft Boot Manager)" --class windows --class os {
          insmod part_gpt
          insmod fat
          insmod chain
          search --no-floppy --fs-uuid --set=root B6E9-B042
          chainloader /EFI/Microsoft/Boot/OSSBoot.efi
        }
      '';
    };
  };
  virtualisation.docker.enable = true;
  environment.systemPackages = [ pkgs.docker-compose ];
  users.users.${config.my.machine.username}.extraGroups = [ "docker" ];
}
