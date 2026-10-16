{ config, lib, ... }:
{
  options.my.niri.greeterExtraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Target-specific Dank Greeter output and display configuration.";
  };

  config.services.displayManager.dms-greeter.compositor.customConfig = ''
    hotkey-overlay {
        skip-at-startup
    }
    environment {
        DMS_RUN_GREETER "1"
    }
    gestures {
        hot-corners {
            off
        }
    }
    input {
        touchpad {
            tap
            natural-scroll
        }
    }
  '' + config.my.niri.greeterExtraConfig;
}
