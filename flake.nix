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
    # Standalone patch, pinned independently from the desktop configuration.
    dms-tray-focus = {
      url = "github:hecongnan/dms-niri-tray-focus/7d86167f9ffb5183c4f367a31913f60969c5df4e";
      flake = false;
    };
    nvim-config = {
      url = "github:hecongnan/nvim-config/e62ab4660fa4a893971ec4c8811f804c9d557ce7";
      flake = false;
    };
    computer-use.url = "github:lihaoze123/niri-computer-use";
    # Keep the desktop version used in the blueprint and the cached backend pins.
    codex-desktop = {
      url = "github:ilysenko/codex-desktop-linux/25f308a66ae97ff01e6d3d77f9ff0cf685138575";
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
        codex-cli-layout = import ./tests/codex-cli-layout.nix { inherit pkgs; };
        scratchpad = pkgs.runCommand "scratchpad-check" {
          nativeBuildInputs = [ pkgs.python3 ];
        } ''
          mkdir -p assets/scripts tests
          cp ${./assets/scripts/scratchpad.py} assets/scripts/scratchpad.py
          cp ${./tests/test-scratchpad.py} tests/test-scratchpad.py
          cp ${./tests/test_scratchpad.py} tests/test_scratchpad.py
          cp ${./tests/test_auto_workspaces.py} tests/test_auto_workspaces.py
          python3 tests/test-scratchpad.py
          touch "$out"
        '';
        desktop-state = pkgs.runCommand "desktop-state-check" {
          nativeBuildInputs = [ pkgs.python3 ];
        } ''
          python3 ${./tests/desktop-state.py} ${./assets/scripts/seed-desktop-state.py} ${./assets/desktop-state}
          touch "$out"
        '';

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
