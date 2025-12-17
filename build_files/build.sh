#!/bin/bash

set -ouex pipefail

mkdir -p /usr/libexec/
cat << 'EOF' > /usr/libexec/install-zena.sh
#!/bin/bash
set -euxo pipefail
OCI_DIR="/etc/zena"
echo "Importing OCI image from \${OCI_DIR} into local container storage..."
skopeo copy \
    --preserve-digests \
    "oci:/etc/zena:stable" \
    "containers-storage:ghcr.io/jianzcar/zena:stable"
echo "Image imported. Switching BootC to use the local image..."
/usr/bin/bootc switch --transport containers-storage "ghcr.io/jianzcar/zena:stable" --apply
echo "BootC switch complete; the system will reboot into the new image."
EOF
chmod +x /usr/libexec/install-zena.sh

cat << 'EOF' > /etc/systemd/system/install-zena.service
[Unit]
Description=BootC switch installer
Requires=local-fs.target
After=local-fs.target containers-storage.service multi-user.target
ConditionPathExists=/etc/zena

[Service]
Type=oneshot
ExecStart=/usr/libexec/install-zena.sh
StandardOutput=tty
StandardError=tty
TTYPath=/dev/console
TTYReset=yes

RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable install-zena.service
systemctl mask systemd-remount-fs
sudo sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
