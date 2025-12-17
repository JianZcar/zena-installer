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
Requires=local-fs.target
RequiresMountsFor=/etc/zena
After=local-fs.target sysinit.target

[Service]
Type=oneshot
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/libexec/install-zena.sh
StandardOutput=journal+console
StandardError=journal+console
TTYPath=/dev/console
TTYReset=yes
RemainAfterExit=yes

Restart=on-failure
RestartSec=30
StartLimitIntervalSec=600
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable install-zena.service
systemctl mask systemd-remount-fs
sudo sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
