{ config, lib, pkgs, osConfig, ... }:
let
  initializeNvim = pkgs.writeShellApplication {
    name = "initialize-aurora-nvim";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      directory=${lib.escapeShellArg "${config.xdg.configHome}/nvim"}
      install -d -m 700 "$directory"
      if [ ! -e "$directory/init.lua" ]; then
        install -m 600 ${../../assets/init.lua} "$directory/init.lua"
      fi
    '';
  };
in
{
  programs.fish = { enable = true; interactiveShellInit = "set -g fish_greeting"; };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = { add_newline = false; };
  };
  programs.zoxide = { enable = true; enableFishIntegration = true; };
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = { auto_sync = false; update_check = false; enter_accept = false; };
  };
  programs.direnv = {
    enable = osConfig.my.features.direnv.enable;
    nix-direnv.enable = osConfig.my.features.direnv.enable;
  };
  programs.neovim = {
    enable = true;
    # The wrapper subtracts 1 from this priority, giving the HM package 5.
    # Keep the original profile Neovim (priority 4) as the selected nvim command.
    package = lib.setPrio 6 pkgs.neovim-unwrapped;
    # HM's provider initialization must not own the user's writable init.lua.
    sideloadInitLua = true;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
  };
  # Writable local init.lua, created once. No repository checkout or plugins needed.
  home.activation.initializeNvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe initializeNvim}
  '';
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "FiraCode Nerd Font";
      font_size = 11;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
    };
  };
}
