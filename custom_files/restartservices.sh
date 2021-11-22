#
#~/restartservices.sh
#
#!/bin/sh
sudo systemctl restart dnsmasq.service
sudo systemctl restart dnsmasq
sudo systemctl restart rpcbind
sudo systemctl restart nfs-kernel-server