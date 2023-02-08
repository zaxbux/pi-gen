#!/bin/bash -e

on_chroot << EOF
apt autoremove --yes
EOF
