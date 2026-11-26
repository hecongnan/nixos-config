{ config, lib, pkgs, ... }:
let
  vscodeAssets = ../../assets/vscode;
  laptopSettings = builtins.fromJSON (builtins.readFile (vscodeAssets + "/settings.json"));
  laptopTasks = builtins.fromJSON (builtins.readFile (vscodeAssets + "/tasks.json"));
  userTasks = pkgs.writeText "vscode-user-tasks.json" (builtins.toJSON (laptopTasks // {
    tasks = map (task: task // { command = "${pkgs.gcc}/bin/g++"; }) laptopTasks.tasks;
  }));
  setiFolder = pkgs.vscode-utils.buildVscodeExtension {
    pname = "seti-folder";
    version = "1.3.0";
    vscodeExtPublisher = "l-igh-t";
    vscodeExtName = "vscode-theme-seti-folder";
    vscodeExtUniqueId = "l-igh-t.vscode-theme-seti-folder";
    src = pkgs.fetchFromGitHub {
      owner = "L-IGH-T";
      repo = "Seti-folder";
      rev = "065a8d943afa7f486d9ca88203617c3a184586d6";
      hash = "sha256-as9WnQBTKpLlu7RF7zpIv+r0t03WkAdzN88Tg/13TpQ=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/$installPrefix"
      cp -r "$src"/{package.json,LICENSE,ThirdPartyNotices.txt,icons} "$out/$installPrefix/"
      runHook postInstall
    '';
    meta.license = lib.licenses.mit;
  };
  restoreExtensions = pkgs.writeShellApplication {
    name = "restore-vscode-extensions";
    runtimeInputs = [ pkgs.vscode pkgs.gnugrep ];
    text = ''
      installed=$(code --list-extensions)
      pending=()
      while IFS= read -r extension; do
        if ! grep -Fxiq -- "''${extension%@*}" <<< "$installed"; then
          pending+=(--install-extension "$extension")
        fi
      done < ${../../assets/vscode/gallery-extensions.txt}
      if (( ''${#pending[@]} )); then
        code --force "''${pending[@]}"
      fi
    '';
  };
  code = pkgs.writeShellApplication {
    name = "code-x11";
    text = ''
      ${pkgs.systemd}/bin/systemctl --user start --no-block aurora-vscode-extensions.service || true
      exec ${pkgs.coreutils}/bin/env -u NIXOS_OZONE_WL \
        ${pkgs.vscode}/bin/code --ozone-platform=x11 --disable-gpu "$@"
    '';
  };
  desktopCode = "${pkgs.systemd}/bin/systemd-run --user --quiet --collect --same-dir --property=ExitType=cgroup -- ${lib.getExe code}";
  codex = pkgs.callPackage ../../pkgs/codex-cli { };
in
{
  home.packages = [ code codex pkgs.jetbrains-mono ];
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    profiles.default = {
      mutableUserSettings = true;
      userSettings = laptopSettings // {
        "labuladong-leetcode.workspaceFolder" = "${config.home.homeDirectory}/.lcpr";
        "java.jdt.ls.java.home" = "${pkgs.jdk21}/lib/openjdk";
        launch = laptopSettings.launch // {
          configurations = map (launch: launch // {
            miDebuggerPath = "${pkgs.gdb}/bin/gdb";
          }) laptopSettings.launch.configurations;
        };
      };
      extensions = [ pkgs.vscode-extensions.sdras.night-owl setiFolder ];
    };
  };
  home.activation.seedVscodeTasks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    vscode_user=${lib.escapeShellArg "${config.xdg.configHome}/Code/User"}
    if [[ ! -e "$vscode_user/tasks.json" && ! -L "$vscode_user/tasks.json" ]]; then
      run ${pkgs.coreutils}/bin/install -d -m 700 "$vscode_user"
      run ${pkgs.coreutils}/bin/cp --update=none -- ${userTasks} "$vscode_user/tasks.json"
      run ${pkgs.coreutils}/bin/chmod u+w "$vscode_user/tasks.json"
    fi
  '';
  systemd.user.services.aurora-vscode-extensions = {
    Unit.Description = "Restore VS Code Marketplace extensions";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe restoreExtensions;
    };
  };
  home.file.".local/bin/codex".source = "${codex}/bin/codex";
  xdg.desktopEntries.code = {
    name = "Visual Studio Code";
    genericName = "Text Editor";
    comment = "Code Editing. Redefined.";
    exec = "${desktopCode} %F";
    icon = "vscode";
    terminal = false;
    startupNotify = true;
    settings.StartupWMClass = "Code";
    categories = [ "Utility" "TextEditor" "Development" "IDE" ];
    mimeType = [ "application/x-code-workspace" "text/plain" "inode/directory" ];
    actions.new-empty-window = {
      name = "New Empty Window";
      exec = "${desktopCode} --new-window %F";
      icon = "vscode";
    };
  };
  xdg.desktopEntries.code-url-handler = {
    name = "Visual Studio Code - URL Handler";
    exec = "${desktopCode} --open-url %U";
    icon = "vscode";
    terminal = false;
    noDisplay = true;
    startupNotify = true;
    categories = [ "Utility" "TextEditor" "Development" "IDE" ];
    mimeType = [ "x-scheme-handler/vscode" ];
  };
}
