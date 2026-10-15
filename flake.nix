{
  description = "Aurora's minimal Niri desktop";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/v1.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    computer-use.url = "github:lihaoze123/niri-computer-use";
    # Keep the desktop version used in the blueprint and the cached backend pins.
    codex-desktop = {
      url = "github:ilysenko/codex-desktop-linux/03c41abe0d1119c5a015fe29d3aad821ad4549bf";
      inputs.nixpkgs.follows = "computer-use/codex-desktop-linux/nixpkgs";
      inputs.flake-utils.follows = "computer-use/codex-desktop-linux/flake-utils";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://niri-computer-use.cachix.org" ];
    extra-trusted-public-keys = [ "niri-computer-use.cachix.org-1:K5LGfljid+PkRn02OLbwsmngqBCoLkbDi9hRMCnsOTg=" ];
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      host = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/aurora ];
      };
      preview = host.extendModules { modules = [ ./tests/preview.nix ]; };
      partitionTestHost = host.extendModules {
        modules = [{
          my.machine = {
            diskDevice = nixpkgs.lib.mkForce "/dev/vdb";
            efiDevice = nixpkgs.lib.mkForce "/dev/vdb9";
            rootDevice = nixpkgs.lib.mkForce "/dev/vdb10";
          };
        }];
      };
    in
    {
      nixosConfigurations.aurora = host;
      # Only for --vm-test; never install this entry on a real target.
      nixosConfigurations.aurora-preview = preview;
      packages.${system}.flclash = pkgs.callPackage ./pkgs/flclash { };
      checks.${system} = {
        flclash-loader = import ./tests/flclash-loader.nix {
          inherit pkgs;
          flclash = self.packages.${system}.flclash;
        };
        desktop = preview.config.system.build.toplevel;
        disko = preview.config.system.build.diskoScript;
        installation = preview.config.system.build.installTest;
        partition-safety = import ./tests/partition-safety.nix {
          inherit pkgs;
          diskoScript = partitionTestHost.config.system.build.diskoScript;
        };
      };
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
