{ lib, ... }:
let
  localModules = [
    ./local/boot.nix
    ./local/hardware-configuration.nix
    ./local/machine.nix
  ];
  hasLocalModules = builtins.all builtins.pathExists localModules;
in
{
  imports = [
    ../../modules/nixos/docker.nix
  ] ++ lib.optionals hasLocalModules localModules ++ [
    ./power.nix
    ../../modules/nixos
  ];

  assertions = [
    {
      assertion = hasLocalModules;
      message = "Laptop configuration requires hosts/laptop/local/{boot,hardware-configuration,machine}.nix. Use a path: flake so Nix can read the Git-ignored modules. See docs/multi-host.md.";
    }
  ];

  my.machine.hostName = lib.mkDefault "laptop";

  my.features = {
    bluetooth.enable = true;
    graphicalBoot.enable = true;
    computerUse.enable = true;
  };
}
