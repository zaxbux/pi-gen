#!/bin/bash -e

#install -m 644 files/resolv.conf "${ROOTFS_DIR}/etc/"

on_chroot <<EOF
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
EOF