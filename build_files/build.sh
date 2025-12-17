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
echo "Installing Arch(zena) please wait..."
/usr/bin/bootc switch --transport containers-storage "ghcr.io/jianzcar/zena:stable" --apply
EOF
chmod +x /usr/libexec/install-zena.sh

cat << 'EOF' > /etc/systemd/system/install-zena.service
[Unit]
Description=Zena installer
After=local-fs.target sysinit.target getty@tty1.service
Before=getty@tty1.service
Requires=local-fs.target
RequiresMountsFor=/etc/zena

[Service]
Type=oneshot
ExecStartPre=-/bin/systemctl stop getty@tty1.service
ExecStart=/usr/libexec/install-zena.sh
ExecStartPost=/bin/systemctl start getty@tty1.service
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /usr/lib/systemd/system-preset/02-install-zena.preset
enable install-zena.service
EOF

if ! rpm -q dnf5 >/dev/null; then
    rpm-ostree install dnf5 dnf5-plugins
fi

dnf5 install @core @container-management @hardware-support
systemctl enable install-zena.service
systemctl mask systemd-remount-fs

sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

sed -i -f - /usr/lib/os-release << 'EOF'
s|^PRETTY_NAME=.*|PRETTY_NAME=\"Arch (zena) Installer\"|
EOF
