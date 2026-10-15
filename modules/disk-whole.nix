{ config, lib, ... }:
{
  config = lib.mkIf (config.my.machine.diskLayout == "whole-disk") {
    # Whole-disk UEFI candidate only. Dual boot requires a separate reviewed layout.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    disko.devices.disk.main = {
      type = "disk";
      device = config.my.machine.diskDevice;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [ "-F" "32" ];
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" ]; };
                "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" ]; };
                "/nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
    # Memory pressure protection; disk swap and hibernation await hardware details.
    zramSwap.enable = true;
  };
}
