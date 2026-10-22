{ config, lib, pkgs, inputs, osConfig, ... }:
let
  initializeNvim = pkgs.writeShellApplication {
    name = "initialize-aurora-nvim";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      directory=${lib.escapeShellArg "${config.xdg.configHome}/nvim"}
      install -d -m 700 "$directory"
      if [ ! -e "$directory/init.lua" ]; then
        cp -a ${inputs.nvim-config}/. "$directory/"
        chmod -R u+rwX "$directory"
      fi
    '';
  };
in
{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  home.sessionVariables.NVIM_SYSTEM_TOOLS = "${import ../../pkgs/nvim-system-tools { inherit pkgs; }}";
  home.file.".profile".text = ''
    # Home Manager session variables plus standalone user commands.
    if [ -r "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    fi
    export PATH="$HOME/.local/bin:$PATH"
  '';
  programs.fish = { enable = true; interactiveShellInit = "set -g fish_greeting"; };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character.success_symbol = "[~](bold green)";

      # jj-starship 统一处理 Git 和 Jujutsu 仓库，关闭内置 git 模块避免重复显示
      git_branch.disabled = true;
      git_commit.disabled = true;
      git_status.disabled = true;
      custom.jj = {
        when = "${pkgs.jj-starship}/bin/jj-starship detect";
        command = "${pkgs.jj-starship}/bin/jj-starship";
        shell = [ "sh" ];
        format = "$output ";
      };
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "auto";
    extraOptions = [ "--group-directories-first" ];
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
  # Seed the pinned complete config once; Lazy can still update writable lock files.
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
      background = "#282a36";
      foreground = "#f8f8f2";
      cursor = "#f8f8f2";
      selection_background = "#44475a";
      selection_foreground = "#f8f8f2";
      color0 = "#21222c";
      color1 = "#ff5555";
      color2 = "#50fa7b";
      color3 = "#f1fa8c";
      color4 = "#bd93f9";
      color5 = "#ff79c6";
      color6 = "#8be9fd";
      color7 = "#f8f8f2";
      color8 = "#6272a4";
      color9 = "#ff6e6e";
      color10 = "#69ff94";
      color11 = "#ffffa5";
      color12 = "#d6acff";
      color13 = "#ff92df";
      color14 = "#a4ffff";
      color15 = "#ffffff";
    };
  };
}
