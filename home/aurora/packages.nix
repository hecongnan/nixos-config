# Return the package list to keep its original position in Home Manager merging.
{ lib, pkgs, osConfig }:
with pkgs; [
  microsoft-edge nautilus file-roller loupe papers gnome-text-editor
  zip unzip p7zip
  # Imported from the existing user profile, using the same locked Nixpkgs.
  # Native package priorities match the profile (notably LibreOffice and Neovim).
  btop fastfetch ffmpeg google-chrome gpu-screen-recorder
  imagemagick img2pdf libreoffice neovim nodejs
  qq scrcpy tesseract vim vlc vscode wechat-uos
  wf-recorder wireshark wpsoffice zbar
  (import ../../pkgs/nvim-system-tools { inherit pkgs; })
] ++ lib.optionals osConfig.my.features.terminalTools.enable [
  yazi fzf ripgrep fd bat eza
]
