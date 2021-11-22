#
#/nfs/client/chroot.sh
#

echo Entering chroot

sudo mount --bind /dev dev
sudo mount --bind /sys sys
sudo mount --bind /proc proc
sudo chroot .

echo Unmounting chroot partitions
sudo umount dev sys proc

echo Thanks for using chroot.