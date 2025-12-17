#!/bin/bash

set -ouex pipefail

mkdir -p /usr/libexec/
cat << 'EOF' > /usr/libexec/install-zena.sh
#!/bin/bash
set -euxo pipefail
echo "Importing OCI image into local container storage..."
skopeo copy \
    --preserve-digests \
    "oci:/etc/zena:stable" \
    "containers-storage:ghcr.io/jianzcar/zena:stable"
echo "Image imported. Switching Bootc to use the local image..."
/usr/bin/bootc switch --transport containers-storage "ghcr.io/jianzcar/zena:stable" --apply
EOF
chmod +x /usr/libexec/install-zena.sh

cat << 'EOF' > /etc/systemd/system/install-zena.service
[Unit]
Description=Zena installer
After=getty@tty1.service
Wants=getty@tty1.service
RequiresMountsFor=/etc/zena

[Service]
Type=oneshot
ExecStart=/usr/libexec/install-zena.sh
StandardOutput=journal+console
StandardError=journal+console
TTYPath=/dev/console
TTYReset=yes
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable install-zena.service
systemctl mask systemd-remount-fs
sudo sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
