#!/bin/sh
#
# Cross‑NAS Docker socket permission fixer installer
# - On Synology DSM 7+: use Task Scheduler (boot-up task)
# - On other NAS/Linux: install rc.d/init-style script
#
# Behaviour:
#   Ensures /var/run/docker.sock becomes mode 666 after boot,
#   waiting until the socket exists before chmod.

set -e

SCRIPT_NAME="docker-socket-fix.sh"
INSTALL_RC="/usr/local/etc/rc.d"   # Synology / some NAS
INSTALL_ETC_INITD="/etc/init.d"    # Generic Linux / some NAS

# --- Helper: detect Synology DSM ------------------------------------------------

is_synology() {
    if [ -f /etc/synoinfo.conf ] || uname -a 2>/dev/null | grep -qi synology; then
        return 0
    fi
    return 1
}

synology_version() {
    if command -v get_key_value >/dev/null 2>&1 && [ -f /etc.defaults/VERSION ]; then
        get_key_value /etc.defaults/VERSION productversion 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# --- Helper: create the actual fix script content --------------------------------

create_fix_script() {
    cat << 'EOF'
#!/bin/sh
# Docker socket permission fixer
# Wait until /var/run/docker.sock exists, then chmod 666

SOCK="/var/run/docker.sock"

# Wait until Docker socket exists
while [ ! -S "$SOCK" ]; do
    sleep 1
done

chmod 666 "$SOCK"
EOF
}

# --- Install for generic Linux / non‑Synology NAS --------------------------------

install_generic_rc() {
    echo "Detected non‑Synology system."
    echo "Attempting to install rc/init script for Docker socket fix."

    TARGET_DIR=""
    if [ -d "$INSTALL_RC" ]; then
        TARGET_DIR="$INSTALL_RC"
    elif [ -d "$INSTALL_ETC_INITD" ]; then
        TARGET_DIR="$INSTALL_ETC_INITD"
    else
        echo "No rc.d or init.d directory found."
        echo "You can still run the fix manually in your own startup system:"
        echo
        create_fix_script
        echo
        echo "Save that script somewhere and call it at boot."
        exit 0
    fi

    TARGET="$TARGET_DIR/$SCRIPT_NAME"

    echo "Installing to: $TARGET"
    create_fix_script | sudo tee "$TARGET" >/dev/null
    sudo chmod 755 "$TARGET"
    sudo chown root:root "$TARGET"

    echo
    echo "Installed $TARGET"
    echo "Now ensure your NAS/startup system runs it at boot."
    echo "For example, on many systems you can enable it with:"
    echo "  sudo update-rc.d $SCRIPT_NAME defaults   (Debian/Ubuntu style)"
    echo
}

# --- Synology DSM path: Task Scheduler instructions ------------------------------

install_synology_task_scheduler_instructions() {
    DSM_VER="$(synology_version)"

    echo "Detected Synology DSM ($DSM_VER)."
    echo
    echo "On DSM 7+, user rc.d scripts are often ignored unless part of a signed package."
    echo "The most reliable method is to use Task Scheduler."
    echo
    echo "Create a new Task Scheduler entry:"
    echo
    echo "  Control Panel → Task Scheduler → Create → Triggered Task → User-defined script"
    echo
    echo "Settings:"
    echo "  - User: root"
    echo "  - Event: Boot-up"
    echo "  - Task Settings → User-defined script:"
    echo
    echo "      # Wait until Docker socket exists"
    echo "      while [ ! -S /var/run/docker.sock ]; do"
    echo "          sleep 1"
    echo "      done"
    echo
    echo "      chmod 666 /var/run/docker.sock"
    echo
    echo "This will ensure Docker is up, the socket exists, and then permissions are fixed."
    echo
    echo "You do NOT need to reference any file in your project or /usr/local/etc/rc.d."
    echo
}

# --- Main ------------------------------------------------------------------------

echo "=== Cross‑NAS Docker Socket Permission Fix Installer ==="
echo

if is_synology; then
    install_synology_task_scheduler_instructions
else
    install_generic_rc
fi

echo
echo "Done."
