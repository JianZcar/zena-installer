#!/bin/bash

set -ouex pipefail

mkdir -p /usr/libexec/
cat << 'EOF' > /usr/libexec/install-zena.sh
#!/usr/bin/env bash
set -euxo pipefail

OCI_DIR="/etc/zena"

IMAGE_REF="ghcr.io/jianzcar/zena:stable"

echo "Importing OCI image from \${OCI_DIR} into local container storage..."
skopeo copy \
    --preserve-digests \
    "oci:\${OCI_DIR}:stable" \
    "containers-storage:\${IMAGE_REF}"

echo "Image imported. Switching BootC to use the local image..."

/usr/bin/bootc switch --transport containers-storage "\${IMAGE_REF}" --apply

echo "BootC switch complete; the system will reboot into the new image."
EOF
chmod +x /usr/libexec/install-zena.sh

cat << 'EOF' > /etc/systemd/system/install-zena.service
[Unit]
Description=BootC switch installer
After=multi-user.target default.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/libexec/install-zena.sh

StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes

RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable install-zena.service
