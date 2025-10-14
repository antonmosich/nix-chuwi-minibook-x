{
  config,
  lib,
  pkgs,
  ...
}:
let
  chuwiCfg = config.hardware.chuwi-minibook-x;
in
{
  # udev rules for accelerometer detection and configuration
  services.udev.extraRules =
    let
      devpaths = {
        hack = {
          display = "*/i2c-*/i2c-MDA6655:00/iio:device0";
          base = "*/i2c-*/*-0015/iio:device1";
        };
        platform = {
          display = "*/i2c-MDA6655:00-mxc4005.display/*";
          base = "*/i2c-MDA6655:00-mxc4005.base/*";
        };
      };
      loadKernelModule =
        if chuwiCfg.driver == "hack" then
          ''
            RUN+="${pkgs.kmod}/bin/modprobe chuwi-ltsm-hack",
          ''
        else
          "";

      accelInitScript = pkgs.writeShellScriptBin "mxc4005-init" ''
        device_path=$(dirname $(grep Synopsys /sys/bus/i2c/devices/i2c-*/name 2>/dev/null | head -n1) | head -n1)/new_device
        echo mxc4005 0x15 > "$device_path"
      '';

      runInitScript =
        if chuwiCfg.driver == "hack" then ''RUN+="${lib.getExe accelInitScript}", '' else "";

      baseAccelerometerRule = ''
        SUBSYSTEM=="iio", KERNEL=="iio*", SUBSYSTEMS=="i2c", \
          DEVPATH=="${devpaths.${chuwiCfg.driver}.base}", \
          ${loadKernelModule} \
          ENV{ACCEL_MOUNT_MATRIX}="${chuwiCfg.mountMatrix}", \
          ENV{ACCEL_LOCATION}="base"
      '';

      displayAccelerometerEnv = ''
        ENV{ACCEL_MOUNT_MATRIX}="${chuwiCfg.mountMatrix}", \
        ENV{ACCEL_LOCATION}="display"'';

      displayAccelerometerRule = ''
        SUBSYSTEM=="iio", KERNEL=="iio*", SUBSYSTEMS=="i2c", \
          DEVPATH=="*/i2c-*/i2c-MDA6655:00/iio:device0", \
          ${runInitScript} ''
      + displayAccelerometerEnv
      + (
        if chuwiCfg.tabletMode.enable then
          ''
            , \
                                ENV{SYSTEMD_WANTS}="iio-sensor-proxy.service"''
        else if chuwiCfg.autoDisplayRotation.enable then
          ''
            , \
                                ENV{SYSTEMD_WANTS}="iio-sensor-proxy.service"''
        else
          ""
      );

      iioPermissionsRule = ''
        SUBSYSTEM=="iio", KERNEL=="iio*", MODE="0660", GROUP="iio"
      '';
      udevRulesList = [
        iioPermissionsRule
        displayAccelerometerRule
        baseAccelerometerRule
      ];
    in
    lib.concatStringsSep "\n" udevRulesList;
}
