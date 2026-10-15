{ ... }:
{
  # Retained options only; omitted services have no modules or flake inputs.
  my.features = {
    bluetooth.enable = true;
    graphicalBoot.enable = true;
    computerUse.enable = true;
    nixLd.enable = false;
    appimage.enable = false;
    phoneIntegration.enable = false;
    direnv.enable = false;
    terminalTools.enable = false;
  };
}
