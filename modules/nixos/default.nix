{ inputs, ... }:
{
  imports = [
    ./base.nix
    ./desktop.nix
    ./greeter.nix
    ./graphical-boot
    ./computer-use
    ./features.nix
    ./flclash.nix
    inputs.home-manager.nixosModules.home-manager
  ];
}
