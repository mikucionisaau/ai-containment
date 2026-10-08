#!/bin/bash
set -e

TARGET_USER="${USERNAME:-appuser}"
TARGET_UID="${USERID:-1000}"
TARGET_GID="${GROUPID:-1000}"

echo "Setting up user $TARGET_USER with UID=$TARGET_UID GID=$TARGET_GID"

EXISTING_USER=$(getent passwd "$TARGET_UID" | cut -d: -f1)
if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$TARGET_USER" ]; then
    echo "Evicting $EXISTING_USER squatting on $TARGET_UID"
    EXISTING_GID=$(id -g "$EXISTING_USER")
    groupadd -g 9999 _displaced 2>/dev/null || true
    usermod -u 9999 -g 9999 "$EXISTING_USER"
fi

EXISTING_GROUP=$(getent group "$TARGET_GID" | cut -d: -f1)
if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$TARGET_USER" ]; then
    echo "Evicting $EXISTING_GROUP squatting on $TARGET_GID"
    groupmod -g 9998 "$EXISTING_GROUP"
fi

if ! getent group "$TARGET_USER" > /dev/null 2>&1; then
    echo "Creating group"
    groupadd -g "$TARGET_GID" "$TARGET_USER"
else
    echo "Modifying group"
    groupmod -g "$TARGET_GID" "$TARGET_USER"
fi

if ! getent passwd "$TARGET_USER" > /dev/null 2>&1; then
    echo "Creating user"
    useradd -u "$TARGET_UID" -g "$TARGET_GID" \
            -d "/home/$TARGET_USER" \
            -s /bin/bash -M "$TARGET_USER"
else
    echo "Modifying user"
    usermod -u "$TARGET_UID" -g "$TARGET_GID" \
            -d "/home/$TARGET_USER" "$TARGET_USER"
fi

echo "Adding $TARGET_USER to sudo group"
usermod -aG sudo "$TARGET_USER"

if [ -n "${PASSWORD:-}" ]; then
    echo "${TARGET_USER}:${PASSWORD}" | chpasswd
    echo "🔑  Password set for ${TARGET_USER}"
    # Unset it so it doesn't linger in the process environment
    unset PASSWORD
else
    echo "⚠️   No \$PASSWORD set — only key-based auth will work."
    echo "    Start with: docker run -e PASSWORD=secret ... or use add-ssh-key.sh"
fi

exec "$@"
