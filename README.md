# nix-chuwi-minibook-x

This repository provides NixOS and Home Manager modules for the Chuwi Minibook X devices. The goal is to deliver a smooth out-of-the-box experience, including hardware enablement, device-specific tweaks, and user experience improvements.

![Example installation](image.png)

## Overview

This flake contains two main modules:

1. **NixOS module**: Enables hardware support and system-level configuration for the Chuwi Minibook X.
2. **Home Manager module**: Provides user-level automatic display rotation (autorotation) based on device orientation.

**Example:**

```nix
hardware.chuwi-minibook-x = {
  mountMatrix = "1,0,0;0,1,0;0,0,1"; # For Chuwi Minibook X N150 (default)
  # mountMatrix = "0,-1,0;1,0,0;0,0,1"; # For Chuwi Minibook X N100
  tabletMode.enable = true; # (default)
  autoDisplayRotation = {
    enable = true; # (default)
    commands = {
      normal = "niri msg output \"DSI-1\" transform normal";
      bottomUp = "niri msg output \"DSI-1\" transform 180";
      rightUp = "niri msg output \"DSI-1\" transform 270";
      leftUp = "niri msg output \"DSI-1\" transform 90";
    };
  };
};
```

By default, tablet mode and autorotation is enabled in the hardware abstraction example, and the commands are set up for the `niri` compositor. You can override these commands to suit your environment (e.g., use `wlr-randr`, `xrandr`, or custom scripts).

## Kernel Module, Udev, and Systemd Integration

- The kernel module (`chuwi-ltsm-hack`) is built and loaded automatically for tablet mode support. The platform driver is not used by default (requires kernel patches).
- Udev rules are installed to detect and configure the accelerometers, set the correct mount matrix, and trigger the tablet mode service.
- Systemd services are set up for both system-level (tablet mode detection) and user-level (auto display rotation) integration.

## Credits

- Upstream userspace daemon and kernel module: [minibook-dual-accelerometer](https://github.com/rhalkyard/minibook-dual-accelerometer)

## Troubleshooting

If the display rotation or tablet mode features are not working as expected, you can run the following troubleshooting script (installed system-wide):

```sh
minibookx-troubleshoot
```

This script will check for relevant hardware, udev, and service status, and print helpful diagnostic messages.
