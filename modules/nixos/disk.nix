{ config, lib, ... }:
let cfg = config.my.machine;
in
{
  imports = [ ./disk-whole.nix ];
  options.my.machine = {
    diskLayout = lib.mkOption {
      type = lib.types.enum [ "existing-partitions" "whole-disk" ];
      default = "existing-partitions";
    };
    efiDevice = lib.mkOption { type = lib.types.str; };
    rootDevice = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf (cfg.diskLayout == "existing-partitions") {
    assertions = [
      {
        assertion = cfg.efiDevice != cfg.diskDevice && cfg.rootDevice != cfg.diskDevice && cfg.efiDevice != cfg.rootDevice;
        message = "Partial installation must select two distinct partitions, never the whole disk.";
      }
    ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    # The existing 488 MiB Arch ESP is reused without resizing any partition.
    boot.loader.systemd-boot.configurationLimit = 3;
    zramSwap.enable = true;
    disko.devices.disk = {
      arch-esp = {
        type = "disk";
        device = cfg.efiDevice;
        destroy = false;
        content = {
          type = "filesystem";
          format = "vfat";
          # A 488 MiB ESP otherwise defaults to FAT16, rejected by some firmware.
          extraArgs = [ "-F" "32" ];
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      arch-root = {
        type = "disk";
        device = cfg.rootDevice;
        destroy = false;
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
}
