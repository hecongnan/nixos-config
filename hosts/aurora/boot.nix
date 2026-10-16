{ lib, ... }:
{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = true;
    timeout = lib.mkForce 5;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      configurationLimit = 3;
      timeoutStyle = lib.mkForce "menu";
      extraEntries = ''
        menuentry "Windows (Microsoft Boot Manager)" --class windows --class os {
          insmod part_gpt
          insmod fat
          insmod chain
          search --no-floppy --fs-uuid --set=root B6E9-B042
          chainloader /EFI/Microsoft/Boot/OSSBoot.efi
        }
      '';
    };
  };
}
