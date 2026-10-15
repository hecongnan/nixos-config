{ config, pkgs, ... }:
let
  package = pkgs.callPackage ../pkgs/flclash { };
  username = config.my.machine.username;
in
{
  # Match the upstream helper protocol: root helper, single authorized desktop UID,
  # group-owned Unix socket, unchanged hashed Core beside the helper executable.
  systemd.services.flclash-helper = {
    description = "FlClash TUN helper for ${username}";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "nftables.service" ];
    environment = {
      FLCLASH_HELPER_OWNER_UID = toString config.users.users.${username}.uid;
      FLCLASH_HELPER_OWNER_GID = toString config.users.groups.${username}.gid;
    };
    path = with pkgs; [ iproute2 nftables ];
    serviceConfig = {
      ExecStart = "${package}/opt/FlClash/FlClashHelperService";
      User = "root";
      Group = username;
      RuntimeDirectory = "flclash";
      RuntimeDirectoryMode = "0755";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
