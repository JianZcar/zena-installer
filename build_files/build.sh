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
Wants=getty-pre.target
Before=getty-pre.target
After=local-fs-pre.target
RequiresMountsFor=/etc/zena

[Service]
Type=oneshot
ExecStart=/usr/libexec/install-zena.sh
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
RemainAfterExit=yes

[Install]
WantedBy=getty-pre.target
EOF

cat << 'EOF' > /usr/lib/systemd/system-preset/02-install-zena.preset
enable install-zena.service
EOF

if ! rpm -q dnf5 >/dev/null; then
    rpm-ostree install dnf5 dnf5-plugins
fi

rm -f /root && mkdir -p /root
dnf5 -y install @core @container-management @hardware-support
systemctl enable install-zena.service
systemctl mask systemd-remount-fs

sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
sed -i -e 's|^PRETTY_NAME=.*|PRETTY_NAME="Arch (zena) Installer"|' /usr/lib/os-release
