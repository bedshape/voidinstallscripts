pvcreate /dev/mapper/rbs
vgcreate vols /dev/mapper/rbs
lvcreate -L 4G -n swap vols && mkswap /dev/vols/swap 
lvcreate -L 1G -n boot vols && mkfs.ext4 /dev/vols/boot
lvcreate -l 100%FREE -n root vols && mkfs.ext4 /dev/vols/root



