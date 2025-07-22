#!/usr/bin/env bash

set -euo pipefail

# Check for chuwi-ltsm-hack kernel module
echo "[INFO] Checking for chuwi-ltsm-hack kernel module..."
if lsmod | grep -q '^chuwi_ltsm_hack'; then
    echo "[OK] chuwi-ltsm-hack kernel module is loaded."
else
    echo "[FAIL] chuwi-ltsm-hack kernel module is NOT loaded."
fi

# Check for Synopsys I2C devices
if grep -q Synopsys /sys/bus/i2c/devices/i2c-*/name 2>/dev/null; then
    echo "[OK] Synopsys I2C device found."
else
    echo "[WARN] Synopsys I2C device not found."
fi

# Check for presence of custom udev rules for Chuwi Minibook X
echo "[INFO] Checking for Chuwi Minibook X udev rules..."
UDEV_RULES_FILE="/etc/udev/rules.d/99-chuwi-minibook-x.rules"
EXPECTED_KEYWORDS=("ACCEL_MOUNT_MATRIX" "ACCEL_LOCATION" "tablet-mode.service" "iio-sensor-proxy.service" "auto-display-rotation.service" "mxc4005")

# Try to find the rules file or matching rules in /run/udev/rules.d or /etc/udev/rules.d
found_rule=0
for rulesfile in /etc/udev/rules.d/*.rules /run/udev/rules.d/*.rules; do
    [ -e "$rulesfile" ] || continue
    if grep -q "ACCEL_MOUNT_MATRIX" "$rulesfile"; then
        found_rule=1
        echo "[OK] Found Chuwi Minibook X udev rules in $rulesfile"
        # Check for all expected keywords
        missing_keywords=()
        for kw in "${EXPECTED_KEYWORDS[@]}"; do
            if ! grep -q "$kw" "$rulesfile"; then
                missing_keywords+=("$kw")
            fi
        done
        if [ ${#missing_keywords[@]} -eq 0 ]; then
            echo "[OK] All expected keywords found in udev rules."
        else
            echo "[WARN] Missing keywords in udev rules: ${missing_keywords[*]}"
        fi
    fi
done
if [ $found_rule -eq 0 ]; then
    echo "[FAIL] Chuwi Minibook X udev rules not found in /etc/udev/rules.d or /run/udev/rules.d."
    echo "[INFO] Please check your NixOS configuration and rebuild if necessary."
fi


# Detect all IIO devices and check for accelerometers
echo "[INFO] Scanning for IIO devices and accelerometers..."
found_accel=0
for dev in /sys/bus/iio/devices/iio:device*; do
    [ -e "$dev" ] || continue
    devnum=${dev##*/iio:device}
    namefile="$dev/name"
    if [ -f "$namefile" ]; then
        chipname=$(cat "$namefile")
    else
        chipname="<unknown>"
    fi
    # Heuristic: look for 'accel' in the name or known accelerometer chip names
    if echo "$chipname" | grep -qiE 'accel|mxc4005'; then
        found_accel=1
        echo "[OK] Accelerometer found: $dev ($chipname)"
    else
        echo "[INFO] Non-accelerometer IIO device: $dev ($chipname)"
    fi
    # Check for corresponding /dev node
    devnode="/dev/iio:device$devnum"
    if [ -e "$devnode" ]; then
        ls -l "$devnode"
    else
        echo "[WARN] $devnode missing. Check udev rules."
    fi
done
if [ $found_accel -eq 0 ]; then
    echo "[FAIL] No accelerometers found among IIO devices."
fi



# Check systemd service statuses (system and user)
echo "[INFO] Checking systemd service statuses..."

# tablet-mode.service and iio-sensor-proxy.service are system services
if systemctl status tablet-mode.service 1>/dev/null 2>&1; then
    systemctl status tablet-mode.service
    echo "[INFO] tablet-mode.service (system) status above."
else
    echo "[WARN] tablet-mode.service (system) not found or not active."
fi

if systemctl status iio-sensor-proxy.service 1>/dev/null 2>&1; then
    systemctl status iio-sensor-proxy.service
    echo "[INFO] iio-sensor-proxy.service (system) status above."
else
    echo "[WARN] iio-sensor-proxy.service (system) not found or not active."
fi

# auto-display-rotation.service is a user service
if systemctl --user status auto-display-rotation.service 1>/dev/null 2>&1; then
    systemctl --user status auto-display-rotation.service
    echo "[INFO] auto-display-rotation.service (user) status above."
else
    echo "[WARN] auto-display-rotation.service (user) not found or not active."
fi

# Show recent logs for services (system and user)
echo "[INFO] Showing last 20 logs for relevant services..."
if journalctl -b -u tablet-mode.service -n 1 --no-pager 1>/dev/null 2>&1; then
    journalctl -b -u tablet-mode.service -n 20 --no-pager
    echo "[INFO] Last 20 logs for tablet-mode.service (system) above."
else
    echo "[WARN] No logs found for tablet-mode.service (system)."
fi

if journalctl -b -u iio-sensor-proxy.service -n 1 --no-pager 1>/dev/null 2>&1; then
    journalctl -b -u iio-sensor-proxy.service -n 20 --no-pager
    echo "[INFO] Last 20 logs for iio-sensor-proxy.service (system) above."
else
    echo "[WARN] No logs found for iio-sensor-proxy.service (system)."
fi

if [ "$EUID" -eq 0 ]; then
    echo "[WARN] Running as root: user service logs may not be visible. Switch to the target user for user service log checks."
fi
if journalctl --user -b -u auto-display-rotation.service -n 1 --no-pager 1>/dev/null 2>&1; then
    journalctl --user -b -u auto-display-rotation.service -n 20 --no-pager
    echo "[INFO] Last 20 logs for auto-display-rotation.service (user) above."
else
    echo "[WARN] No logs found for auto-display-rotation.service (user)."
fi
