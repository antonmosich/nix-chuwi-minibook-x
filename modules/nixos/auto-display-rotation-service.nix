{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.chuwi-minibook-x.autoDisplayRotation;
in {
  config = mkIf cfg.enable {
    systemd.user.services.auto-display-rotation = {
      description = "Auto Display Rotation";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target" "iio-sensor-proxy.service"];
      wants = ["iio-sensor-proxy.service"];

      serviceConfig = {
        Type = "simple";
        ExecStart = let
          autoDisplayRotationScript = pkgs.writeShellApplication {
            name = "auto-display-rotation";
            runtimeInputs = with pkgs; [iio-sensor-proxy mawk niri];
            text = ''
              monitor-sensor | mawk -W interactive '/Accelerometer orientation changed:/ { print $NF; fflush();}' | while read -r line
              do
                case "$line" in
                  normal)
                    ${cfg.commands.normal}
                    ;;
                  bottom-up)
                    ${cfg.commands.bottomUp}
                    ;;
                  right-up)
                    ${cfg.commands.rightUp}
                    ;;
                  left-up)
                    ${cfg.commands.leftUp}
                    ;;
                esac
              done
            '';
          };
        in "${lib.getExe autoDisplayRotationScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
