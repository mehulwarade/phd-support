########################
# /nfs/mkdir.sh        #
# /nfs/rootfs.tar.gz   #
########################

# Usage
# sh mkdir nodeXX MAC-ADDRESS
# sh mkdir node1 dc-a6-32-c1-a8-02

sudo rm -r $1

sudo mkdir -p $1

sudo tar -C $1 -zxvf rootfs.tar.gz

sudo mv $1/etc/fstab $1/etc/fstab-old

echo "192.168.5.10:/tftpboot/"$2" /boot nfs defaults,ver=4.1,proto-tcp 0 0" | sudo tee -a $1/etc/fstab

echo "192.168.5.10:/home/mehul/shared_fs /home/mehul/shared_fs nfs rw,hard,intr,rsize=8192,wsize=8192,timeo=14 0 0" | sudo tee -a $1/etc/fstab

echo "proc /proc proc defaults 0 0" | sudo tee -a $1/etc/fstab

# Changing hostname

echo | sudo tee $1/etc/hostname
echo "$1" | sudo tee $1/etc/hostname

echo | sudo tee $1/etc/hosts
echo "127.0.0.1 localhost" | sudo tee $1/etc/hosts
echo "127.0.1.1 $1"| sudo tee -a $1/etc/hosts
echo "::1 localhost ip6-localhost ip6-loopback"| sudo tee -a $1/etc/hosts
echo "ff02::1 ip6-allnodes"| sudo tee -a $1/etc/hosts
echo "ff02::2 ip6-allrouters"| sudo tee -a $1/etc/hosts

# Hostname Changed

mkdir -p $1/home/mehul/shared_fs