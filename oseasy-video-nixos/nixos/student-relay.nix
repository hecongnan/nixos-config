# Alternative: import this on a NixOS student relay, NOT on the laptop.
{ ... }:
{
  imports = [ ./module.nix ];

  services.oseasyVideo.relay = {
    enable = true;
    teacher = "10.115.4.137";
    interface = "enp3s0"; # Replace with the student classroom interface name.
    localAddress = null; # Read its current IPv4, or specify a static student IP.
    udpPort = 7778;
    httpHost = "0.0.0.0";
    httpPort = 17778;
    openFirewall = true; # Only the interface above gets these inbound ports.
  };
}
