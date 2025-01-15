read -p "enter locale: " locale 
read -p "enter rbs_block: " rbs_block 
read -p "enter hostname: " hostname

echo "$hostname" > /etc/hostname 

uuid=$(blkid -s UUID -o value $rbs_block)

# Enable cryptodisk in GRUB
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub || handle_error

# Replace the GRUB_CMDLINE_LINUX_DEFAULT line in /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=4 rd.lvm.vg=vols rd.luks.uuid=$uuid\"|" /etc/default/grub || handle_error

# Update /etc/default/libc-locales with the locale
locale_line="${locale}.UTF-8 UTF-8"
echo $locale_line >> /etc/default/libc-locales || handle_error

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="void" --recheck --modules="tpm" --disable-shim-lock || handle_error
grub-mkconfig -o /boot/grub/grub.cfg || handle_error

# Reconfigure the system
xbps-reconfigure -fa || handle_error

# Set root password
echo "set root password:"
passwd || handle_error

# Prompt for a new user account
read -p "enter the new user account name: " username

# Add the new user account
useradd -m $username || handle_error

# Add the new user account to the specified groups
usermod -aG kmem,wheel,tty,disk,lp,audio,video,storage,network,kvm,input,plugdev,usbmon $username || handle_error

# Set password for the new user account
echo "set password for ($username):"
passwd $username || handle_error

# Enable services
ln -s /etc/sv/dbus /etc/runit/runsvdir/default/ || handle_error
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/ || handle_error

# Reminder to edit rc.conf
echo "remember to edit /etc/rc.conf"
echo "run the following command to edit sudoers file:" 
echo "EDITOR=nvim visudo"
echo "you may reboot after you have made your desired changes"
# Final confirmation message
