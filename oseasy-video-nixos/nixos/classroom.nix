# Import this file from configuration.nix on the NixOS laptop.
{ ... }:
{
  imports = [ ./module.nix ];

  services.oseasyVideo.laptop = {
    enable = true;
    remote = "10.115.3.82";
    remotePort = 17778;
    interface = "eno2"; # Replace with the NixOS laptop's actual interface name.
    source = null; # Read the current interface IPv4; do not hard-code the old IP.
    port = 17780;
    background = false; # Set true to keep the local URL available after boot.
  };

  # Keep the existing Windows student relay running; it need not be migrated.
  services.oseasyVideo.relay.enable = false;
}
