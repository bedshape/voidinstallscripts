two scripts that allow for a pretty painless encrypted void linux install

it is assumed that you are using a UEFI amd64 system and have already partitioned your drive into an efi and root/boot/swap partition

prior to cloning this repo partition your drives and, run:

xmirror <-- choose geographic mirror

xi <-- sync

xi git openssl <-- git + openssl to clone repo

cd voidinstallscripts 

chmod +x * <-- scripts executable

./install.sh <-- run
