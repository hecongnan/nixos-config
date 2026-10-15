{ config, pkgs, ... }:
{
  programs.niri.enable = true;
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${config.my.machine.username}";
  };
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.accounts-daemon.enable = true;
  programs.dconf.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  environment.systemPackages = with pkgs; [ wl-clipboard brightnessctl ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  fonts = {
    packages = with pkgs; [
      material-design-icons noto-fonts-cjk-sans noto-fonts-color-emoji
      nerd-fonts.fira-code
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans CJK SC" ];
      monospace = [ "FiraCode Nerd Font" "Noto Sans CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
