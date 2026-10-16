{ inputs, ... }:
{
  imports = [
    ../../modules/nixos/docker.nix
    ../../oseasy-video-nixos/nixos/classroom.nix
  ] ++ [
    ./boot.nix
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
}
