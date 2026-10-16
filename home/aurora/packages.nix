# Return the package list to keep its original position in Home Manager merging.
{ lib, pkgs, osConfig }:
with pkgs; [
  microsoft-edge nautilus file-roller loupe papers gnome-text-editor
  zip unzip p7zip
] ++ lib.optionals osConfig.my.features.terminalTools.enable [
  yazi fzf ripgrep fd bat eza
]
