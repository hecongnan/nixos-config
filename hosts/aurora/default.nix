{ inputs, ... }:
{
  imports = [
    ../../modules/nixos/docker.nix
    ./boot.nix
    ./machine.nix
    ./features.nix
    ./hardware-configuration.nix
    ./platform.nix
    ./display.nix
    ../../modules/nixos
    # Keep the classroom packages in their existing merge order.
    ./classroom.nix
    ../../modules/nixos/disk.nix
    inputs.disko.nixosModules.disko
  ];
}
