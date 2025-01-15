#!/bin/bash

# Function to handle errors
handle_error() {
    echo "error. exiting."
    exit 1
}

# Prompt for mapper name
read -p "Enter the mapper name (default: rbs): " mapper_name
mapper_name=${mapper_name:-rbs}

# Prompt for block name of the rbs partition
read -p "Enter the block name of the rbs partition (e.g., /dev/sdaX): " rbs_block

# Prompt for block name of the EFI partition
read -p "Enter the block name of the EFI partition (e.g., /dev/sdaY): " efi_block

# Encrypt the rbs partition
cryptsetup luksFormat --type luks1 $rbs_block || handle_error

# Open the encrypted partition
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

# Bootstrap Void Linux
mkdir -p /mnt/var/db/xbps/keys 
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys || handle_error

XBPS_ARCH=x86_64 xbps-install -S -r /mnt -R "https://repo-fastly.voidlinux.org/current" base-system linux linux-firmware-amd neovim NetworkManager polkit pipewire alsa-pipewire mesa lvm2 cryptsetup grub-x86_64-efi efibootmgr fastfetch elogind dbus curl alsa-utils bsdtar || handle_error

# Confirmation message
echo "successfully bootstrapped."

# Generate /etc/fstab using genfstab
./genfstab -U /mnt >> /mnt/etc/fstab || handle_error

cp inchroot.sh /mnt/

echo "<<<>>>

run './inchroot'.sh now

<<<>>>" 
# Enter chroot environment
xchroot /mnt /bin/bash || handle_error


