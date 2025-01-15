#!/bin/bash

mount /dev/vols/root /mnt
swapon /dev/vols/swap
mount --mkdir /dev/vols/boot /mnt/boot
mount --mkdir /dev/nvme0n1p1 /mnt/efi

mkdir -p /mnt/var/db/xbps/keys 
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys

XBPS_ARCH=x86_64 xbps-install -S -r /mnt -R "https://repo-default.voidlinux.org/current" base-system linux linux-firmware-amd neovim NetworkManager polkit pipewire alsa-pipewire mesa lvm2 cryptsetup grub-x86_64-efi efibootmgr fastfetch elogind dbus curl alsa-utils bsdtar 
