#!/usr/bin/env bash
# Resets all USB host controllers of the system.
# This is useful in case one stopped working
# due to a faulty device having been connected to it.

# Re-exec as root. From a terminal use sudo; otherwise use a GUI
# privilege prompt (pkexec) so it works when launched from rofi/i3.
if [ "$(id -u)" -ne 0 ]; then
    self="$(readlink -f "$0")"
    if [ -t 0 ] && [ -t 1 ]; then
        exec sudo "$self" "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        exec pkexec "$self" "$@"
    else
        exec sudo "$self" "$@"
    fi
fi

base="/sys/bus/pci/drivers"
sleep_secs="1"

# This might find a sub-set of these:
# * 'ohci_hcd' - USB 3.0
# * 'ehci-pci' - USB 2.0
# * 'xhci_hcd' - USB 3.0
echo "Looking for USB standards ..."
for usb_std in "$base/"?hci[-_]?c*
do
    echo "* USB standard '$usb_std' ..."
    for dev_path in "$usb_std/"*:*
    do
        dev="$(basename "$dev_path")"
        echo "  - Resetting device '$dev' ..."
        printf '%s' "$dev" | tee "$usb_std/unbind" > /dev/null
        sleep "$sleep_secs"
        printf '%s' "$dev" | tee "$usb_std/bind" > /dev/null
        echo "    done."
    done
    echo "  done."
done
echo "done."
