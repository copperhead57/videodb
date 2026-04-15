#!/bin/sh
echo "=== Node.js Installer (Linux Mint) ==="

pause() {
    printf "\nPress Enter to continue, or Ctrl+C to cancel..."
    read dummy
    echo ""
}

# ------------------------------------------------------------
# STEP 1 — Check if Node is already installed
# ------------------------------------------------------------
echo "--- Step 1: Checking for existing Node installation ---"

node -v >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[OK] Node is already installed: $(node -v)"
    echo "[OK] npm version: $(npm -v)"
    echo ""
    printf "Do you want to reinstall Node? (y/N): "
    read reinstall

    case "$reinstall" in
        y|Y)
            echo "Proceeding with reinstall..."
            ;;
        *)
            echo "Keeping existing Node installation."
            echo "=== Node installer complete ==="
            exit 0
            ;;
    esac
else
    echo "[INFO] Node is not installed."
fi

pause


# ------------------------------------------------------------
# STEP 2 — Choose installation method
# ------------------------------------------------------------
echo "--- Step 2: Choose Node installation method ---"
echo "1) NodeSource (system-wide, recommended)"
echo "2) nvm (per-user, developer-friendly)"
echo ""

printf "Select option (1 or 2): "
read choice

case "$choice" in
    1)
        method="nodesource"
        ;;
    2)
        method="nvm"
        ;;
    *)
        echo "[ERROR] Invalid choice."
        exit 1
        ;;
esac

pause


# ------------------------------------------------------------
# STEP 3 — Install Node using chosen method
# ------------------------------------------------------------
if [ "$method" = "nodesource" ]; then
    echo "--- Installing Node via NodeSource ---"

    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt install -y nodejs

    if [ $? -ne 0 ]; then
        echo "[FAIL] NodeSource installation failed."
        exit 1
    fi

    echo "[OK] NodeSource installation complete."
fi


if [ "$method" = "nvm" ]; then
    echo "--- Installing Node via nvm ---"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Load nvm into current shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    nvm install --lts

    if [ $? -ne 0 ]; then
        echo "[FAIL] nvm installation failed."
        exit 1
    fi

    echo "[OK] nvm installation complete."
fi

pause


# ------------------------------------------------------------
# STEP 4 — Verify installation
# ------------------------------------------------------------
echo "--- Step 4: Verifying Node installation ---"

node -v >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[OK] Node version: $(node -v)"
else
    echo "[FAIL] Node not found after installation."
    exit 1
fi

npm -v >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[OK] npm version: $(npm -v)"
else
    echo "[FAIL] npm not found after installation."
    exit 1
fi

echo ""
echo "=== Node installation complete ==="
printf "Press Enter to exit..."
read dummy
