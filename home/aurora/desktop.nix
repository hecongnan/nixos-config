{ config, lib, pkgs, inputs, osConfig, ... }:
let
  dmsVersion = lib.removePrefix "v" (lib.trim (builtins.readFile "${inputs.dms}/quickshell/VERSION"));
  # Keep the CLI and patched UI on the same explicitly pinned DMS release.
  dmsPackage = (inputs.dms.lib.mkDmsShell pkgs).overrideAttrs (old: {
    # The release archive includes the exact Go vendor tree for offline compilation.
    src = pkgs.fetchurl {
      url = "https://github.com/duxlabs-dev/dux-shell/releases/download/v${dmsVersion}/dms-cli-${dmsVersion}.tar.gz";
      hash = "sha256-uqaknYkS57fFVKC+DFWkQkIPh9x14A7lVpiAkq54eBI=";
    };
    sourceRoot = "dms-cli-${dmsVersion}";
    vendorHash = null;
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.patch ];
    postInstall = old.postInstall + ''
      patch --batch --fuzz=0 -d "$out/share/quickshell/dms" -p1 < ${./dms-tray-focus.patch}
    '';
  });
  trayFocusShell = "${dmsPackage}/share/quickshell/dms";
  trayFocus = pkgs.writeShellApplication {
    name = "dms-focus-tray-window";
    runtimeInputs = [ pkgs.python3 pkgs.niri pkgs.systemd ];
    text = ''
      exec python3 ${inputs.dms-tray-focus}/focus-tray-window.py "$@"
    '';
  };

  initialize = pkgs.writeShellApplication {
    name = "initialize-aurora-dms";
    runtimeInputs = [ pkgs.coreutils pkgs.python3 ];
    text = ''
      python3 ${../../assets/scripts/seed-desktop-state.py} \
        --snapshot ${../../assets/desktop-state} \
        --config-home ${lib.escapeShellArg config.xdg.configHome} \
        --state-home ${lib.escapeShellArg config.xdg.stateHome} \
        --wallpaper ${lib.escapeShellArg "${config.home.homeDirectory}/.background/wallpaper.svg"}
      install -d -m 700 ${lib.escapeShellArg "${config.home.homeDirectory}/Pictures/Screenshots"}
    '';
  };
in
{
  imports = [ inputs.dms.homeModules.dank-material-shell ./scratchpad.nix ];
  programs.dank-material-shell = {
    enable = true;
    package = dmsPackage;
    quickshell.package = pkgs.quickshell;
    systemd.enable = true;
    systemd.target = "graphical-session.target";
    enableCalendarEvents = false;
    enableVPN = false;
    enableDynamicTheming = false;
    enableAudioWavelength = false;
  };
  home.file.".background/wallpaper.svg".source = ../../assets/wallpaper.svg;
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  gtk = {
    enable = true;
    iconTheme = { name = "Adwaita"; package = pkgs.adwaita-icon-theme; };
  };
  qt = { enable = true; platformTheme.name = "qtct"; };
  xdg.configFile."qt6ct/qt6ct.conf".text = "[Appearance]\nicon_theme=Papirus-Dark\n";
  xdg.configFile."DankMaterialShell/plugins/quickCapture".source = ../../vendor/quickCapture;
  home.packages = with pkgs; [ papirus-icon-theme adw-gtk3 satty grim slurp xwayland-satellite ];
  home.sessionVariables.QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  systemd.user.sessionVariables.QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  xdg.configFile."niri/config.kdl".source = ../../assets/niri.kdl;
  xdg.configFile."niri/computer-use.kdl" = lib.mkIf osConfig.my.features.computerUse.enable {
    source = ../../assets/computer-use.kdl;
  };
  home.activation.initializeDms = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe initialize}
  '';
  systemd.user.services.dms = {
    Unit = { After = [ "niri.service" ]; Requisite = [ "niri.service" ]; };
    Service = {
      # The package wrapper supplies -c, which takes precedence over DMS_SHELL_DIR.
      ExecStart = lib.mkForce "${lib.getExe dmsPackage} --config ${trayFocusShell} run --session";
      ExecStartPre = lib.getExe initialize;
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QT_QPA_PLATFORMTHEME=qt6ct"
        "QT_QPA_PLATFORMTHEME_QT6=qt6ct"
        "QS_ICON_THEME=Papirus-Dark"
        "DMS_SHELL_DIR=${trayFocusShell}"
        "DMS_TRAY_FOCUS_HELPER=${lib.getExe trayFocus}"
      ];
    };
  };
  # Native niri integration launches Xwayland satellite on demand.
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 300; command = "${dmsPackage}/bin/dms ipc call lock lock"; }
      { timeout = 600; command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors"; }
    ];
    events = {
      before-sleep = "${dmsPackage}/bin/dms ipc call lock lock";
      lock = "${dmsPackage}/bin/dms ipc call lock lock";
    };
  };
}
