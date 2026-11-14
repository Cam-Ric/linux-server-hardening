#!/usr/bin/env bash

set -euo pipefail

# BlackBox - Departmental User Provisioning
# Usage: sudo bash create-user.sh USERNAME GROUP
# Example: sudo bash create-user.sh test-finance finance

if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] Run this script as root."
    exit 1
fi

if [[ "$#" -ne 2 ]]; then
    echo "Usage: sudo bash $0 USERNAME GROUP"
    exit 1
fi

USERNAME="$1"
GROUP="$2"

# Allowed departmental groups
ALLOWED_GROUPS=(
    finance
    management
    human-resources
    marketing
    developers
    it-support
)

# Validate username
if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "[ERROR] Invalid username."
    exit 1
fi

# Validate department
VALID_GROUP=false

for department in "${ALLOWED_GROUPS[@]}"; do
    if [[ "$GROUP" == "$department" ]]; then
        VALID_GROUP=true
        break
    fi
done

if [[ "$VALID_GROUP" != true ]]; then
    echo "[ERROR] Department not allowed: $GROUP"
    exit 1
fi

# Check existing user and group
if getent passwd "$USERNAME" >/dev/null; then
    echo "[ERROR] User already exists: $USERNAME"
    exit 1
fi

if ! getent group "$GROUP" >/dev/null; then
    echo "[ERROR] Group does not exist: $GROUP"
    exit 1
fi

echo "=== BLACKBOX | USER PROVISIONING ==="
echo "Username:   $USERNAME"
echo "Department: $GROUP"
echo

read -r -p "Create this account? [y/N]: " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "[INFO] Operation cancelled."
    exit 0
fi

# Create user with home directory and /etc/skel
useradd -m -k /etc/skel -g "$GROUP" -s /bin/bash "$USERNAME"

# Set an initial password interactively
passwd "$USERNAME"

# Force password change on first login
# Password aging policy
# Minimum: 180 days
# Maximum: 360 days
# Warning: 30 days
chage -m 1 -M 360 -W 30 "$USERNAME"

# Force password change on first login
chage -d 0 "$USERNAME"

echo
echo "[SUCCESS] User provisioned."
id "$USERNAME"
passwd -S "$USERNAME"
chage -l "$USERNAME
