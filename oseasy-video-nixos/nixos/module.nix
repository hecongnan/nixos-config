{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types;
  cfg = config.services.oseasyVideo;
  package = pkgs.callPackage ./package.nix { };
  laptopArgs = [
    "--remote" cfg.laptop.remote
    "--remote-port" (toString cfg.laptop.remotePort)
    "--interface" cfg.laptop.interface
    "--port" (toString cfg.laptop.port)
  ] ++ lib.optionals (cfg.laptop.source != null) [ "--source" cfg.laptop.source ];
  relayArgs = [
    "--teacher" cfg.relay.teacher
    "--interface" cfg.relay.interface
    "--udp-port" (toString cfg.relay.udpPort)
    "--http-host" cfg.relay.httpHost
    "--http-port" (toString cfg.relay.httpPort)
  ] ++ lib.optionals (cfg.relay.localAddress != null) [ "--local" cfg.relay.localAddress ];
  commonService = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.StartLimitIntervalSec = 0;
    environment.PYTHONUNBUFFERED = "1";
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      Restart = "always";
      RestartSec = 3;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" ];
    };
  };
in
{
  options.services.oseasyVideo = {
    laptop = {
      enable = mkEnableOption "the laptop classroom-video player and local proxy";
      remote = mkOption {
        type = types.str;
        default = "10.115.3.82";
        description = "Reachable student relay IPv4 address or hostname.";
      };
      remotePort = mkOption {
        type = types.port;
        default = 17778;
        description = "Student relay HTTP port.";
      };
      interface = mkOption {
        type = types.str;
        default = "wlan0";
        description = "Laptop interface whose current IPv4 is used as the source address.";
      };
      source = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Explicit source IPv4, or null to read the interface at startup.";
      };
      port = mkOption {
        type = types.port;
        default = 17780;
        description = "Loopback HTTP port presented to the player.";
      };
      background = mkOption {
        type = types.bool;
        default = false;
        description = "Start the persistent loopback proxy at boot, without a GUI player.";
      };
    };

    relay = {
      enable = mkEnableOption "the student-side UDP multicast to HTTP relay";
      teacher = mkOption {
        type = types.str;
        default = "10.115.4.137";
        description = "Teacher source IPv4; the multicast address is derived from it.";
      };
      interface = mkOption {
        type = types.str;
        default = "eth0";
        description = "Student classroom interface used to join the multicast group.";
      };
      localAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Student classroom IPv4, or null to read the interface at startup.";
      };
      udpPort = mkOption {
        type = types.port;
        default = 7778;
        description = "Incoming teacher multicast UDP port.";
      };
      httpHost = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "HTTP listening IPv4; 0.0.0.0 accepts connections on all local IPv4 addresses.";
      };
      httpPort = mkOption {
        type = types.port;
        default = 17778;
        description = "Student HTTP stream port.";
      };
      openFirewall = mkEnableOption "video UDP and HTTP ports on the classroom interface";
    };
  };

  config = mkMerge [
    (mkIf (cfg.laptop.enable || cfg.relay.enable) {
      environment.systemPackages = [ package ];
      assertions = [ {
        assertion = !(cfg.laptop.enable && cfg.relay.enable
          && cfg.laptop.port == cfg.relay.httpPort);
        message = "oseasyVideo laptop and relay HTTP ports must differ on the same host.";
      } ];
    })

    (mkIf cfg.laptop.enable {
      environment.systemPackages = [
        pkgs.mpv
        (pkgs.writeShellApplication {
          name = "oseasy-play";
          runtimeInputs = [ pkgs.mpv ];
          text = ''
            exec ${package}/bin/oseasy-play-raw ${lib.escapeShellArgs laptopArgs} "$@"
          '';
        })
      ];
      systemd.services.oseasy-laptop = lib.recursiveUpdate commonService {
        description = "OsEasy loopback classroom video proxy";
        wantedBy = lib.optionals cfg.laptop.background [ "multi-user.target" ];
        serviceConfig.ExecStart = lib.escapeShellArgs
          ([ "${package}/bin/oseasy-proxy" ] ++ laptopArgs ++ [ "--bind" "127.0.0.1" ]);
      };
      # No inbound firewall port is needed for a loopback-only HTTP service.
    })

    (mkIf cfg.relay.enable {
      systemd.services.oseasy-relay = lib.recursiveUpdate commonService {
        description = "OsEasy teacher multicast to HTTP video relay";
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = lib.escapeShellArgs
          ([ "${package}/bin/oseasy-relay" ] ++ relayArgs);
      };
      networking.firewall.interfaces = mkIf cfg.relay.openFirewall {
        ${cfg.relay.interface} = {
          allowedUDPPorts = [ cfg.relay.udpPort ];
          allowedTCPPorts = lib.optionals (cfg.relay.httpHost != "127.0.0.1")
            [ cfg.relay.httpPort ];
        };
      };
    })
  ];
}
