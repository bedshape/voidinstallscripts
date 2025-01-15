#!/bin/bash

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="void" --recheck --modules="tpm" --disable-shim-lock && grub-mkconfig -o /boot/grub/grub.cfg

echo "remember to generate initramfs (xbps-reconfigure -fa)"
