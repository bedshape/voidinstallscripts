scripts that allow for a pretty painless encrypted void linux install.

it is assumed that you are using a UEFI amd64 system and have already partitioned your drive.

your partitions should look something like this:
/dev/nvme0n1p1 -> to be used for efi 
/dev/nvme0n1p2 -> will be encrypted and contain LVM volumes for / (root), boot, and swap

you only need to partition with your preferred tool, the script will format the partitions, prompt your for a luks password, and format the lvm volumes for you.

prior to cloning this repo, you will need to run (it is assumed you are in the live iso):

xmirror <-- choose geographic mirror

xi <-- sync

xi git openssl <-- git + openssl to clone repo

cd voidinstallscripts 

chmod +x *.sh <-- scripts executable

./install.sh <-- run
