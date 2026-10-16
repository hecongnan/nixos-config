{ config, ... }:
{
  networking.hostName = config.my.machine.hostName;
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;
  networking.firewall.enable = true;
}
