#!/bin/bash

cp /proc/mounts /etc/fstab
blkid >> /etc/fstab

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "rd.lvm.vg=vols rd.luks.uuid=" >> /etc/default/grub
blkid >> /etc/default/grub

echo "edit /etc/default/grub"



