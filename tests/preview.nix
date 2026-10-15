# VM installation test only: retain the real Btrfs/disko configuration.
{ config, lib, pkgs, ... }:
let
  flclash = pkgs.callPackage ../pkgs/flclash { };
  rime = pkgs.fcitx5-rime.override { rimeDataPkgs = [ pkgs.rime-ice ]; };
in
{
  my.machine = {
    installationReady = lib.mkForce true;
    diskDevice = lib.mkForce "/dev/vda";
    diskLayout = lib.mkForce "whole-disk";
  };
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_net" "ahci" ];
  # The test driver requires a serial console even with graphical boot enabled.
  boot.consoleLogLevel = lib.mkForce 7;
  # The installation test bind-mounts the host store through 9p. Its ownership
  # cannot be changed to the guest's nixbld group when HM connects to the daemon.
  nix.settings.build-users-group = lib.mkForce "";
  nix.settings.substituters = lib.mkForce [ ];
  # Disko's boot test shares the store but does not populate the installed DB.
  # Real nixos-anywhere installations copy and register their closure normally.
  system.activationScripts.registerPreviewHomeManager.text = ''
    NIX_REMOTE=local ${pkgs.nix}/bin/nix-store --load-db < ${pkgs.closureInfo {
      rootPaths = [ config.home-manager.users.aurora.home.activationPackage ];
    }}/registration
  '';
  disko.tests.extraChecks = ''
    try:
        machine.wait_for_unit("home-manager-aurora.service")
    except Exception:
        print(machine.succeed("journalctl -b -u home-manager-aurora.service --no-pager"))
        print(machine.succeed("journalctl -b -u nix-daemon.service --no-pager"))
        raise
    machine.wait_for_unit("flclash-helper.service")
    machine.wait_for_unit("sshd.service")
    machine.wait_for_unit("ydotoold.service")
    machine.succeed("id -nG aurora | grep -w ydotool")
    machine.succeed("test -c /dev/uinput && test -S /run/ydotoold/socket")
    machine.succeed("runuser -u aurora -- test -w /dev/uinput")
    machine.succeed("runuser -u aurora -- /run/current-system/sw/bin/niri validate --config /home/aurora/.config/niri/config.kdl")
    machine.succeed("runuser -u aurora -- /run/current-system/sw/bin/codex-computer-use --help")
    machine.succeed("test -S /run/flclash/helper.sock")
    core_hash = machine.succeed("${pkgs.jq}/bin/jq -r .coreSha256 ${flclash}/opt/FlClash/manifest.json").strip()
    ping_url = "http://localhost/ping?coreSha256=" + core_hash
    machine.succeed("${pkgs.util-linux}/bin/runuser -u aurora -- ${pkgs.curl}/bin/curl -fsS --unix-socket /run/flclash/helper.sock '" + ping_url + "'")
    machine.fail("${pkgs.curl}/bin/curl -fsS --unix-socket /run/flclash/helper.sock '" + ping_url + "'")
    machine.succeed("test -f /home/aurora/.config/nvim/init.lua && test ! -L /home/aurora/.config/nvim/init.lua")
    machine.succeed("runuser -u aurora -- /etc/profiles/per-user/aurora/bin/nvim --headless '+lua assert(vim.o.shiftwidth == 2)' +qa")
    machine.succeed("${pkgs.util-linux}/bin/runuser -u aurora -- ${pkgs.librime}/bin/rime_deployer --build /home/aurora/.local/share/fcitx5/rime ${rime}/share/rime-data")
    machine.succeed("test -s /home/aurora/.local/share/fcitx5/rime/build/rime_ice.table.bin")
    machine.succeed("echo '-- preserved local edit' >> /home/aurora/.config/nvim/init.lua")
    machine.succeed("systemctl restart home-manager-aurora.service")
    machine.succeed("grep -q 'preserved local edit' /home/aurora/.config/nvim/init.lua")
  '';
}
