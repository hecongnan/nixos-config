{ pkgs, ... }:
let
  edidPath = "edid/aurora-panel-60hz.bin";
  panelFirmware = pkgs.runCommand "aurora-panel-edid" { } ''
    mkdir -p "$out/lib/firmware/edid"
    cp ${./edid/panel-60hz.bin} "$out/lib/firmware/${edidPath}"
  '';
in
{
  # Keep the panel's exact native timing; omit the 50 Hz DRRS downclock mode.
  hardware.firmware = [ panelFirmware ];
  boot.initrd.extraFirmwarePaths = [ edidPath ];
  boot.kernelParams = [ "drm.edid_firmware=eDP-1:${edidPath}" ];
}
