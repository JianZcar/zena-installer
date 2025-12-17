#!/bin/bash

set -ouex pipefail

cat << 'EOF' > /usr/local/bin/install-zena.sh
#!/usr/bin/env bash
set -euxo pipefail

# Directory where the OCI image layout was saved at build time
OCI_DIR="/etc/zena"

# Target local reference we will import into container storage
IMAGE_REF="ghcr.io/jianzcar/zena:stable"

echo "Importing OCI image from \${OCI_DIR} into local container storage..."
skopeo copy \
    --preserve-digests \
    "oci:\${OCI_DIR}:stable" \
    "containers-storage:\${IMAGE_REF}"

echo "Image imported. Switching BootC to use the local image..."

# Switch BootC deployment to the local image (no registry pull)
# using containers-storage transport
/usr/bin/bootc switch --transport containers-storage "\${IMAGE_REF}" --apply

echo "BootC switch complete; the system will reboot into the new image."
EOF
chmod +x /usr/local/bin/install-zena.sh

cat << 'EOF' > /etc/systemd/system/install-zena.service
[Unit]
Description=BootC switch installer
After=multi-user.target default.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/install-zena.sh

StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes

RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF


dnf5 -y group install "Core"
dnf5 -y group install "Minimal Install"
systemctl enable install-zena.service
