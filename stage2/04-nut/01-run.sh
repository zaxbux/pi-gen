#!/bin/bash -e

#install -v -m 640 files/	"${ROOTFS_DIR}/etc/nut"

# Install udev rule to restart NUT services if a UPS is hotplugged
install -m 644 files/90-nut-ups.rules "${ROOTFS_DIR}/etc/udev/rules.d/"

export NUT_UPS_NAME="${NUT_UPS_NAME:-ups}"
export NUT_UPS_DRIVER="${NUT_UPS_DRIVER:-usbhid-ups}"
export NUT_UPSD_ADMIN_USER="${NUT_UPSD_ADMIN_USER:-admin}"
export NUT_UPSD_ADMIN_PASS="${NUT_UPSD_ADMIN_PASS:-changeme}"
export NUT_UPSD_PRIMARY_USER="${NUT_UPSD_PRIMARY_USER:-primary}"
export NUT_UPSD_PRIMARY_PASS="${NUT_UPSD_PRIMARY_PASS:-changeme}"
export NUT_UPSD_SECONDARY_USER="${NUT_UPSD_SECONDARY_USER:-seconary}"
export NUT_UPSD_SECONDARY_PASS="${NUT_UPSD_SECONDARY_PASS:-ups}"
# APC: 051D; Cyber Power: 0764
export NUT_UPS_VENDORID="${NUT_UPS_VENDORID}"
# APC: 0002; Cyber Power: 0501
export NUT_UPS_PRODUCTID="${NUT_UPS_PRODUCTID}"

# Configure as network server
sed -i 's/MODE=.*/MODE=netserver/' "${ROOTFS_DIR}/etc/nut/nut.conf"

# Add UPS
# This command can be used to determine values: "nut-scanner -U"
cat << EOF >> "${ROOTFS_DIR}/etc/nut/ups.conf"
[${NUT_UPS_NAME}]
	driver = "${NUT_UPS_DRIVER}"
	port = "auto"
	vendorid = "${NUT_UPS_VENDORID}"
	productid = "${NUT_UPS_PRODUCTID}"
EOF

# Listen on all available interfaces
cat << EOF >> "${ROOTFS_DIR}/etc/nut/upsd.conf"
#LISTEN 0.0.0.0 3493
LISTEN :: 3493
EOF

# Add users
cat << EOF >> "${ROOTFS_DIR}/etc/nut/upsd.users"
[${NUT_UPSD_ADMIN_USER}]
	password = "${NUT_UPSD_ADMIN_PASS}"
	actions = set
	actions = fsd
	instcmds = all

[${NUT_UPSD_PRIMARY_USER}]
	password = "${NUT_UPSD_PRIMARY_PASS}"
	upsmon master

[${NUT_UPSD_SECONDARY_USER}]
	password = "${NUT_UPSD_SECONDARY_PASS}"
	upsmon slave
EOF

# Configure local monitoring
echo -e "\nMONITOR ${NUT_UPS_NAME}@localhost:3493 1 ${NUT_UPSD_PRIMARY_USER} ${NUT_UPSD_PRIMARY_PASS} master" >> "${ROOTFS_DIR}/etc/nut/upsmon.conf"

# Remote systems can be configured to monitor this UPS:
#   MONITOR ups@192.168.0.1:3493 1 secondary ups slave