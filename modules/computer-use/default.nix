{ config, lib, pkgs, inputs, ... }:
{
  imports = [ inputs.computer-use.nixosModules.default ];

  config = lib.mkIf config.my.features.computerUse.enable {
    programs.codexComputerUse = {
      enable = true;
      users = [ config.my.machine.username ];
      package = import ./codex-desktop.nix {
        inherit inputs;
        system = pkgs.stdenv.hostPlatform.system;
      };
    };

    nix.settings = {
      extra-substituters = [ "https://niri-computer-use.cachix.org" ];
      extra-trusted-public-keys = [ "niri-computer-use.cachix.org-1:K5LGfljid+PkRn02OLbwsmngqBCoLkbDi9hRMCnsOTg=" ];
    };
  };
}
