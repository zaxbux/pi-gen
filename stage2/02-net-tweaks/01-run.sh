#!/bin/bash -e

#install -v -d					"${ROOTFS_DIR}/etc/wpa_supplicant"
install -v -m 600 files/eth0.network	"${ROOTFS_DIR}/etc/systemd/network/eth0.network"

on_chroot <<EOF
systemctl enable systemd-networkd
systemctl enable systemd-resolved
EOF
