#!bin/sh

# Usage
# sh tftp-create.sh nodeXX MAC_ADDRESS
# sh tftp-create.sh node11 dc-a6-32-af-b6-b7

echo "Creating tftpboot for $2 called $1"

sudo mkdir -p $2

sudo tar -C $2 -zxvf tftp.tar.gz

sudo mv $2/cmdline.txt $2/cmdline.txt-old

echo "console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.5.10:/nfs/"$1",nfsvers=4.1,proto=tcp,wsize=32768,rsize=32768 rw ip=dhcp rootwait elevator=deadline" | sudo tee -a $2/cmdline.txt

sudo chmod -R 777 $2
sudo chown -R root:root $2