{ config, pkgs, ... }:
{
  virtualisation.docker.enable = true;
  environment.systemPackages = [ pkgs.docker-compose ];
  users.users.${config.my.machine.username}.extraGroups = [ "docker" ];
}
