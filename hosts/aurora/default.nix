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
    ../../modules/nixos/base.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/greeter.nix
    ../../modules/nixos/graphical-boot
    ../../modules/nixos/computer-use
    ../../modules/nixos/features.nix
    ../../modules/nixos/flclash.nix
    ../../modules/nixos/disk.nix
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];
}
