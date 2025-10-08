{nixos-hardware}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.chuwi-minibook-x;
in {
  imports = [
    nixos-hardware.nixosModules.chuwi-minibook-x
    ./udev-rules.nix
    ./tablet-mode-service.nix
    ./auto-display-rotation-service.nix
  ];

  options.hardware.chuwi-minibook-x = {
    mountMatrix = lib.mkOption {
      type = lib.types.str;
      default = "1,0,0;0,1,0;0,0,1";
      description = ''
        Accelerometer mount matrix for udev rules (ACCEL_MOUNT_MATRIX).
      '';
    };

    tabletMode = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tablet mode detection";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../../pkgs/tablet-mode-daemon.nix {};
        description = "The tablet mode detection package.";
      };

      interval = lib.mkOption {
        type = lib.types.number;
        default = 0.5;
        description = "Interval between accelerometer polls (seconds)";
      };

      threshold = lib.mkOption {
        type = lib.types.number;
        default = 45;
        description = "Hinge angle threshold to enter tablet mode (degrees)";
      };

      hysteresis = lib.mkOption {
        type = lib.types.number;
        default = 20;
        description = "Hysteresis to add to hinge angle when leaving tablet mode (degrees)";
      };

      tiltThreshold = lib.mkOption {
        type = lib.types.number;
        default = 20;
        description = "Angle threshold for suppressing state changes when off-horizontal (degrees)";
      };

      jerkThreshold = lib.mkOption {
        type = lib.types.number;
        default = 6;
        description = "Jerk (rate of change of acceleration) threshold for suppressing state changes while moving erratically (m/s^3)";
      };

      extraArguments = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments to pass to the tablet-mode service";
      };
    };
    autoDisplayRotation = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable auto display rotation.";
          };
          requiredPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [pkgs.niri];
            description = "Packages required for the rotation commands";
          };
          commands = lib.mkOption {
            type = lib.types.submodule {
              options = {
                normal = lib.mkOption {
                  type = lib.types.str;
                  default = ''niri msg output "DSI-1" transform normal'';
                  description = "Shell command to run when orientation is normal.";
                };
                bottomUp = lib.mkOption {
                  type = lib.types.str;
                  default = ''niri msg output "DSI-1" transform 180'';
                  description = "Shell command to run when orientation is bottom-up (inverted).";
                };
                rightUp = lib.mkOption {
                  type = lib.types.str;
                  default = ''niri msg output "DSI-1" transform 270'';
                  description = "Shell command to run when orientation is right-up (rotated right).";
                };
                leftUp = lib.mkOption {
                  type = lib.types.str;
                  default = ''niri msg output "DSI-1" transform 90'';
                  description = "Shell command to run when orientation is left-up (rotated left).";
                };
              };
            };
            default = {
              normal = ''niri msg output "DSI-1" transform normal'';
              bottomUp = ''niri msg output "DSI-1" transform 180'';
              rightUp = ''niri msg output "DSI-1" transform 270'';
              leftUp = ''niri msg output "DSI-1" transform 90'';
            };
            description = ''
              Commands to execute for each detected orientation. Each value should be a shell command string.
              Defaults match the current niri usage for DSI-1 output.
            '';
            example = {
              normal = ''echo "normal"'';
              bottomUp = ''echo "bottom-up"'';
              rightUp = ''echo "right-up"'';
              leftUp = ''echo "left-up"'';
            };
          };
        };
      };
      default = {
        enable = true;
        requiredPackages = [pkgs.niri];
        commands = {
          normal = ''niri msg output "DSI-1" transform normal'';
          bottomUp = ''niri msg output "DSI-1" transform 180'';
          rightUp = ''niri msg output "DSI-1" transform 270'';
          leftUp = ''niri msg output "DSI-1" transform 90'';
        };
      };
      description = "Auto display rotation configuration.";
    };
  };

  config = lib.mkMerge [
    {
      hardware.sensor.iio.enable = true;
      boot.extraModulePackages = [
        (pkgs.callPackage ../../pkgs/tablet-mode-kernel-module.nix {
          kernel = config.boot.kernelPackages.kernel;
        })
      ];
      boot.kernelModules = ["chuwi-ltsm-hack"];
      boot.extraModprobeConfig = ''
        options intel-hid force_tablet_mode=Y
      '';

      environment.systemPackages = [
        pkgs.iio-sensor-proxy
        (pkgs.callPackage ../../pkgs/minibookx-troubleshoot.nix {})
      ];
    }
    (lib.mkIf cfg.tabletMode.enable {
      environment.systemPackages = [cfg.tabletMode.package];
    })
  ];
}
