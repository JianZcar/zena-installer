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
echo "Installing Arch (zena) please wait..."
/usr/bin/bootc switch --transport containers-storage "ghcr.io/jianzcar/zena:stable"
echo "Cleaning up local image..."
podman image rm "ghcr.io/jianzcar/zena:stable"
echo "Rebooting"
reboot
EOF
chmod +x /usr/libexec/install-zena.sh

cat << 'EOF' > /etc/systemd/system/install-zena.service
[Unit]
Description=Zena installer
Requires=local-fs.target
RequiresMountsFor=/etc/zena
Before=getty@tty1.service
After=local-fs.target sysinit.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/systemctl stop getty@tty1.service
ExecStart=/usr/libexec/install-zena.sh
StandardOutput=journal+console
StandardError=journal+console
TTYPath=/dev/console
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

rm -f /root && mkdir -p /root
dnf5 -y install @core @container-management @hardware-support @base-graphical
systemctl enable install-zena.service
systemctl mask systemd-remount-fs
systemctl set-default graphical.target

sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
sed -i -e 's|^PRETTY_NAME=.*|PRETTY_NAME="Arch (zena) Installer"|' /usr/lib/os-release
