{ config, lib, pkgs, ... }:
let
  theme = pkgs.runCommand "grub-boreal-1920x1080" { } ''
    mkdir -p "$out"
    cp -r ${./theme}/. "$out/"
  '';
  python = pkgs.python3.withPackages (p: [ p.pillow ]);
  fonts = pkgs.makeFontsConf { fontDirectories = [ pkgs.inter ]; };
  bootPath = (builtins.head config.boot.loader.grub.mirroredBoots).path;
  cfgFile = "${bootPath}/grub/grub.cfg";
  themePath = "${bootPath}/theme";
in
{
  assertions = [{
    assertion = builtins.length config.boot.loader.grub.mirroredBoots == 1;
    message = "Boreal currently supports this host's single GRUB boot partition.";
  }];
  boot.loader.grub = {
    theme = lib.mkForce theme;
    # gfxterm has its own background, shown after leaving the themed menu.
    # Replace NixOS's stock gray logo image as well as the menu theme.
    splashImage = lib.mkForce "${theme}/background.png";
    splashMode = "stretch";
    backgroundColor = "#0b1726";
    gfxmodeEfi = "1920x1080,auto";
    gfxmodeBios = "1920x1080,auto";
    extraInstallCommands = lib.mkAfter ''
      # NixOS writes grub.cfg first. Regenerate images from that exact menu,
      # including rollback generations, submenus and the existing Windows entry.
      if ! FONTCONFIG_FILE=${fonts} ${python}/bin/python3 ${./render-menu.py} \
        --config ${lib.escapeShellArg cfgFile} \
        --theme ${lib.escapeShellArg themePath} \
        --data ${./data} \
        --font ${pkgs.inter}/share/fonts/truetype/Inter.ttc \
        --rsvg ${pkgs.librsvg}/bin/rsvg-convert \
        --check ${pkgs.grub2}/bin/grub-script-check; then
        # A rendering error must never leave an invisible menu. Fall back to
        # GRUB's native text menu; actual boot commands are untouched.
        ${pkgs.gnused}/bin/sed -i '/^[[:space:]]*set theme=/d; /^[[:space:]]*export theme[[:space:]]*$/d' ${lib.escapeShellArg cfgFile}
        echo "Boreal: rendering failed; retained a visible native GRUB menu" >&2
      fi
    '';
  };
}
