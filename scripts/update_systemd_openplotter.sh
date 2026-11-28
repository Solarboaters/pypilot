#!/bin/sh
# Install the service units for an existing account without changing its privileges.
set -eu

if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [service-user]" >&2
    exit 1
fi

service_user=${1:-${SUDO_USER:-}}
if [ -z "$service_user" ]; then
    echo "Specify the existing account that should run pypilot." >&2
    exit 1
fi

if ! service_uid=$(id -u -- "$service_user") || [ "$service_uid" -eq 0 ]; then
    echo "The service account must be an existing non-root user." >&2
    exit 1
fi
service_user=$(id -un -- "$service_user")

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this installer with sudo." >&2
    exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
umask 022
install -d /etc/systemd/system
# Preserve any locally edited units, including those installed by OpenPlotter.
cp -vn "$script_dir"/debian/etc/systemd/system/*.service /etc/systemd/system/

for service in pypilot pypilot_boatimu pypilot_hat; do
    dropin=/etc/systemd/system/$service.service.d
    install -d "$dropin"
    printf '[Service]\nUser=%s\n' "$service_user" > "$dropin/10-pypilot-user.conf"
done
systemctl daemon-reload
