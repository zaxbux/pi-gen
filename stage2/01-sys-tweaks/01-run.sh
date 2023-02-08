#!/bin/bash -e

install -m 755 files/resize2fs_once	"${ROOTFS_DIR}/etc/init.d/"

install -d				"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d"
install -m 644 files/ttyoutput.conf	"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/"

install -m 644 files/50raspi		"${ROOTFS_DIR}/etc/apt/apt.conf.d/"
install -m 644 files/disable_raspi_codec.conf		"${ROOTFS_DIR}/etc/modprobe.d/"
install -m 644 files/disable_raspi_camera.conf		"${ROOTFS_DIR}/etc/modprobe.d/"
install -m 644 files/disable_raspi_drm.conf		"${ROOTFS_DIR}/etc/modprobe.d/"
# Disable VideoCore CMA Shared Memory Driver, since less than 32 MiB are applied
install -m 644 files/disable_vcsm.conf		"${ROOTFS_DIR}/etc/modprobe.d/"

install -m 755 files/rc.local		"${ROOTFS_DIR}/etc/"

install -m 644 files/raspberrypi-sys-mods-lite_20230206_armhf.deb	"${ROOTFS_DIR}/var/cache/apt/archives/"

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	sed -i -Ee 's/^#?[[:blank:]]*PubkeyAuthentication[[:blank:]]*no[[:blank:]]*$/PubkeyAuthentication yes/
s/^#?[[:blank:]]*PasswordAuthentication[[:blank:]]*yes[[:blank:]]*$/PasswordAuthentication no/' "${ROOTFS_DIR}"/etc/ssh/sshd_config
fi

on_chroot << EOF
apt install --yes --no-install-recommends "/var/cache/apt/archives/raspberrypi-sys-mods-lite_20230206_armhf.deb"
EOF

on_chroot << EOF
systemctl disable hwclock.sh
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
systemctl enable regenerate_ssh_host_keys
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	on_chroot << EOF
systemctl disable resize2fs_once
EOF
	echo "leaving QEMU mode"
else
	on_chroot << EOF
systemctl enable resize2fs_once
EOF
fi

on_chroot <<EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r "\$GRP"
done
for GRP in adm dialout users sudo plugdev input gpio spi i2c netdev; do
  adduser $FIRST_USER_NAME \$GRP
done
EOF

if [ -f "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd" ]; then
  # Update sudoers file from raspberrypi-sys-mods with new username
  sed -i "s/^pi /$FIRST_USER_NAME /" "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"
else
  if [ "${FIRST_USER_SUDO_NOPASSWD}" = "1" ]; then
	echo "${FIRST_USER_NAME} ALL=(ALL) NOPASSWD: ALL" > "${ROOTFS_DIR}/etc/sudoers.d/010_${FIRST_USER_NAME}-nopasswd"
  fi
fi

# Change default systemd target
on_chroot << EOF
systemctl set-default multi-user.target
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

# Remove SSH keys created during build process, they should be regenerated on first-boot
rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*
