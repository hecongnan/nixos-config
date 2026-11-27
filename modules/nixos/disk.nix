{ config, lib, ... }:
let cfg = config.my.machine;
in
{
  imports = [ ./disk-whole.nix ];
  options.my.machine = {
    installationReady = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Target hardware and disk layout have been reviewed";
    };
    diskDevice = lib.mkOption { type = lib.types.str; };
    diskLayout = lib.mkOption {
      type = lib.types.enum [ "existing-partitions" "whole-disk" ];
      default = "existing-partitions";
    };
    efiDevice = lib.mkOption { type = lib.types.str; };
    rootDevice = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.installationReady;
          message = "Installation pending: generate target hardware configuration, review disk/boot layout, provide login password, then set my.machine.installationReady.";
        }
        {
          assertion = !(lib.hasInfix "REPLACE" cfg.diskDevice);
          message = "Replace my.machine.diskDevice with the reviewed target disk.";
        }
      ];
    }
    (lib.mkIf (cfg.diskLayout == "existing-partitions") {
      assertions = [
        {
          assertion = cfg.efiDevice != cfg.diskDevice && cfg.rootDevice != cfg.diskDevice && cfg.efiDevice != cfg.rootDevice;
          message = "Partial installation must select two distinct partitions, never the whole disk.";
        }
      ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      # Reuse the existing EFI partition without changing partition boundaries.
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
            # Use FAT32 even when mkfs would default to FAT16 on a small ESP.
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
    })
  ];
}
