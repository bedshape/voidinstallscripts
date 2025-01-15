#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error occurred. Exiting."
    exit 1
}

# Prompt for mapper name
read -p "Enter the mapper name (default: rbs): " mapper_name
mapper_name=${mapper_name:-rbs}

# Prompt for block name of the rbs partition
read -p "Enter the block name of the rbs partition (e.g., /dev/sdaX): " rbs_block

# Prompt for block name of the EFI partition
read -p "Enter the block name of the EFI partition (e.g., /dev/sdaY): " efi_block

# Prompt for locale
read -p "Enter your locale (e.g., en_US): " locale

# Encrypt the rbs partition
echo "Setting up encryption for $rbs_block..."
cryptsetup luksFormat --type luks1 $rbs_block || handle_error

# Open the encrypted partition
echo "Opening the encrypted partition..."
cryptsetup open $rbs_block $mapper_name || handle_error

# Set up the logical volumes
pvcreate /dev/mapper/$mapper_name || handle_error
vgcreate vols /dev/mapper/$mapper_name || handle_error

lvcreate -L 4G -n swap vols && mkswap /dev/vols/swap || handle_error
lvcreate -L 1G -n boot vols && mkfs.ext4 /dev/vols/boot || handle_error
lvcreate -l 100%FREE -n root vols && mkfs.ext4 /dev/vols/root || handle_error

# Format the EFI partition as FAT32
mkfs.fat -F32 $efi_block || handle_error

# Mount the partitions
mount /dev/vols/root /mnt || handle_error
mount --mkdir /dev/vols/boot /mnt/boot || handle_error
mount --mkdir $efi_block /mnt/efi || handle_error

# Enable the swap volume
swapon /dev/vols/swap || handle_error

# Confirmation message
echo "Partitions have been set up, encrypted, and mounted. Swap is enabled."

# Bootstrap Void Linux
mkdir -p /mnt/var/db/xbps/keys 
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys || handle_error

XBPS_ARCH=x86_64 xbps-install -S -r /mnt -R "https://repo-fastly.voidlinux.org/current" base-system linux linux-firmware-amd neovim NetworkManager polkit pipewire alsa-pipewire mesa lvm2 cryptsetup grub-x86_64-efi efibootmgr fastfetch elogind dbus curl alsa-utils bsdtar || handle_error

# Confirmation message
echo "Void Linux has been successfully bootstrapped."

# Enter chroot environment
xchroot /mnt /bin/bash || handle_error

# Generate /etc/fstab using genfstab
./genfstab -U /mnt >> /mnt/etc/fstab || handle_error

# Get the UUID for the rbs partition
uuid=$(blkid -s UUID -o value $rbs_block)

# Enable cryptodisk in GRUB
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub || handle_error

# Replace the GRUB_CMDLINE_LINUX_DEFAULT line in /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=4 rd.lvm.vg=vols rd.luks.uuid=$uuid\"|" /etc/default/grub || handle_error

# Update /etc/default/libc-locales with the locale
locale_line="${locale}.UTF-8 UTF-8"
echo $locale_line >> /etc/default/libc-locales || handle_error

# Reconfigure glibc-locales
xbps-reconfigure -f glibc-locales || handle_error

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="void" --recheck --modules="tpm" --disable-shim-lock || handle_error
grub-mkconfig -o /boot/grub/grub.cfg || handle_error

# Reconfigure the system
xbps-reconfigure -f || handle_error

# Set root password
echo "Set the root password:"
passwd || handle_error

# Prompt for a new user account
read -p "Enter the new user account name: " username

# Add the new user account
useradd -m $username || handle_error

# Add the new user account to the specified groups
usermod -aG kmem,wheel,tty,disk,lp,audio,video,storage,network,kvm,input,plugdev,usbmon $username || handle_error

# Set password for the new user account
echo "Set the password for the new user account ($username):"
passwd $username || handle_error

# Enable services
ln -s /etc/sv/dbus /etc/runit/runsvdir/default/ || handle_error
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/ || handle_error

# Reminder to edit rc.conf
echo "Please remember to edit /etc/rc.conf as needed."

# Final confirmation message
echo "Chroot environment set up, /etc/fstab created, GRUB configuration updated with the UUID for $rbs_block, locale added to /etc/default/libc-locales, GRUB installed and configured, root password set, user account ($username) created, services enabled, and system reconfigured."

