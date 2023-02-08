#!/bin/bash -e

# This sub-stage downloads the raspbian-archive-keyring package and modifies it,
# since the maintainers have not fixed a bug report from 2017 (https://bugs.launchpad.net/raspbian/+bug/1727874)
#
# - The gnupg dependency is removed, since this results in unnecessary additional packages.
# - The postinst script is removed, since it uses the deprecated apt-key command that will be removed after Debian 11

on_chroot << EOF
apt-get download raspbian-archive-keyring=20120528.2 > /dev/null
dpkg-deb -x raspbian-archive-keyring_20120528.2_all.deb raspbian-archive-keyring
dpkg-deb --control raspbian-archive-keyring_20120528.2_all.deb raspbian-archive-keyring/DEBIAN
sed -i '/^Depends: gnupg$/d' raspbian-archive-keyring/DEBIAN/control
rm raspbian-archive-keyring/DEBIAN/postinst
dpkg -b raspbian-archive-keyring raspbian-archive-keyring.deb
dpkg -i raspbian-archive-keyring.deb
apt-mark hold raspbian-archive-keyring
apt-get --yes purge gnupg
EOF

# link to raspbian archive gpg key in new /etc/apt/trusted.gpg.d/ directory
on_chroot << EOF
[[ -f '/usr/share/keyrings/raspbian-archive-keyring.gpg' ]] && ln -sf /usr/share/keyrings/raspbian-archive-keyring.gpg /etc/apt/trusted.gpg.d/raspbian-archive-keyring.gpg
EOF
