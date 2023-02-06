#!/bin/bash -e

install -v -m 644 files/eth0.network	"${ROOTFS_DIR}/etc/systemd/network/eth0.network"

# Disable "Predictive Device Naming" (normally done by raspi-config)
on_chroot <<EOF
ln -sf /dev/null /etc/systemd/network/99-default.link
ln -sf /dev/null /etc/systemd/network/73-usb-net-by-mac.link
EOF

# Enable network services
on_chroot <<EOF
systemctl enable systemd-networkd
systemctl enable systemd-resolved
EOF
