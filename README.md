# PHD Support files and information

# File Tree

| Sr. No. |                   File Name                  | Description                                                                                                                                                               |
|:-------:|:--------------------------------------------:|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|    1    |          Brand_new_install_steps.log         | In detail steps to replicate my cluster setup                                         It includes all the references, known issues, errors and how to solve them and tips |
|    2    |           install_cluster_info.txt           | Very basic tips and steps for cluster setup                                                                                                                               |
|    3    |            cluster_all_ip_info.log           | My cluster info (Ip addresses, router addresses, MAC addresses of Rpi's, etc.)                                                                                            |
|    4    |                 Custom_files/                | All the files I custom built to help my cluster setup process faster or to achieve a certain functionality.                                                               |
|    5    |            Custom_files/chroot.sh            | Shell script to easily chroot into a simulated client environment. (Mount, chroot, exit, umount)                                                                          |
|    6    |      Custom_files/Custom_files_info.txt      | More info on the files in this folder.                                                                                                                                    |
|    7    |           Custom_files/dnsmasq.conf          | My custom built dnsmasq.conf file to run a shell script (dnsmasq.conf.save.hosts.auto.sh) to autoupdate the hosts files when new client connects                          |
|    8    | Custom_files/dnsmasq.conf.save.hosts.auto.sh | Shell script called by dnsmasq.conf whenever a new connection or DHCP request is replied.                                                                                 |
|    9    |              Custom_files/hosts              | /etc/hosts files for reference                                                                                                                                            |
|    10   |        Custom_files/restartservices.sh       | Shell script to restart all the required services faster and cleanly                                                                                                      |