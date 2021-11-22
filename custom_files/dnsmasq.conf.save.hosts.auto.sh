#
#/nfs/dnsmasq.conf.save.hosts.auto.sh
#

#!/bin/sh

#echo "Add del or old arg: $1" >> /nfs/save.hosts.auto.log
#echo "MAC arg: $2" >> /nfs/save.hosts.auto.log
#echo "IP arg: $3" >> /nfs/save.hosts.auto.log
#echo "Hostname arg: $4" >> /nfs/save.hosts.auto.log
#echo "Fourth arg: $4"

if [ $1 = 'new' ]; then
    echo "New lease found with following details:"
    echo "MAC: $2"
    echo "IP Address: $3"
    echo "Hostname: $4"

    date +"<=========   Date [ %d/%m/%Y ] Time [ %H:%M:%S ] ==========>" >> /nfs/save.hosts.auto.log
    echo "New lease found with following details:" >> /nfs/save.hosts.auto.log
    echo "MAC: $2" >> /nfs/save.hosts.auto.log
    echo "IP Address: $3" >> /nfs/save.hosts.auto.log
    echo "Hostname: $4" >> /nfs/save.hosts.auto.log

    echo "$3 $4" >> /etc/hosts
    echo 'Added to /etc/hosts'
    echo 'Added to /etc/hosts' >> /nfs/save.hosts.auto.log

    echo '<====== XXX ======>' >> /nfs/save.hosts.auto.log

fi

if [ $1 = 'old' ]; then
    echo "Old lease found with following details:"
    echo "MAC: $2"
    echo "IP Address: $3"
    echo "Hostname: $4"

    date +"<=========   Date [ %d/%m/%Y ] Time [ %H:%M:%S ] ==========>" >> /nfs/save.hosts.auto.log
    echo "Old lease found with following details:" >> /nfs/save.hosts.auto.log
    echo "MAC: $2" >> /nfs/save.hosts.auto.log
    echo "IP Address: $3" >> /nfs/save.hosts.auto.log
    echo "Hostname: $4" >> /nfs/save.hosts.auto.log
    echo "$3 $4" >> /etc/hosts
    echo 'Added to /etc/hosts'
    echo 'Added to /etc/hosts' >> /nfs/save.hosts.auto.log

    echo '<====== XXX ======>' >> /nfs/save.hosts.auto.log
fi

if [ $1 = 'del' ]; then
    echo "DELETED: Old lease with following details:"
    echo "MAC: $2"
    echo "IP Address: $3"
    echo "Hostname: $4"

    date +"<=========   Date [ %d/%m/%Y ] Time [ %H:%M:%S ] ==========>" >> /nfs/save.hosts.auto.log
    echo "DELETED: Old lease with following details:" >> /nfs/save.hosts.auto.log
    echo "MAC: $2" >> /nfs/save.hosts.auto.log
    echo "IP Address: $3" >> /nfs/save.hosts.auto.log
    echo "Hostname: $4" >> /nfs/save.hosts.auto.log

    echo '<====== XXX ======>' >> /nfs/save.hosts.auto.log
fi

#echo '<====================================>' >> /nfs/save.hosts.auto.log
#echo 'End of this sessions log' >> /nfs/save.hosts.auto.log
#echo '<====================================>' >> /nfs/save.hosts.auto.log

#echo '<====================================>'
#echo 'End of this sessions log'
#echo '<====================================>'