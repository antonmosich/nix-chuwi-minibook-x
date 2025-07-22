{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.hardware.chuwi-minibook-x.tabletMode;
in {
  config = mkIf cfg.enable {
    systemd.services.tablet-mode = {
      description = "Tablet mode detection daemon";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target" "iio-sensor-proxy.service"];
      requires = ["iio-sensor-proxy.service"];

      environment = {
        INTERVAL = toString cfg.interval;
        THRESHOLD = toString cfg.threshold;
        HYSTERESIS = toString cfg.hysteresis;
        TILT_THRESHOLD = toString cfg.tiltThreshold;
        JERK_THRESHOLD = toString cfg.jerkThreshold;
        COMMAND = "${cfg.package}/bin/tabletmodectl";
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/tabletmoded --interval ${toString cfg.interval} --threshold ${toString cfg.threshold} --hysteresis ${toString cfg.hysteresis} --tilt-threshold ${toString cfg.tiltThreshold} --jerk-threshold ${toString cfg.jerkThreshold} $COMMAND ${concatStringsSep " " cfg.extraArguments}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
