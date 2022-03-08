#!/bin/sh

echo "Extracting data from table $1 between $2 and $3"

sleep 5

mysql -u root -pqaz rpi4 -ss -e "select p1 from $1 where timestamp between $2 and $3" >> node1.log
mysql -u root -pqaz rpi4 -ss -e "select p2 from $1 where timestamp between $2 and $3" >> node2.log
mysql -u root -pqaz rpi4 -ss -e "select p3 from $1 where timestamp between $2 and $3" >> node3.log
mysql -u root -pqaz rpi4 -ss -e "select p4 from $1 where timestamp between $2 and $3" >> node4.log

mysql -u root -pqaz rpi4 -ss -e "select p5 from $1 where timestamp between $2 and $3" >> node5.log
mysql -u root -pqaz rpi4 -ss -e "select p9 from $1 where timestamp between $2 and $3" >> node6.log
mysql -u root -pqaz rpi4 -ss -e "select p10 from $1 where timestamp between $2 and $3" >> node7.log
mysql -u root -pqaz rpi4 -ss -e "select p11 from $1 where timestamp between $2 and $3" >> node8.log

mysql -u root -pqaz rpi4 -ss -e "select p12 from $1 where timestamp between $2 and $3" >> node9.log
mysql -u root -pqaz rpi4 -ss -e "select p13 from $1 where timestamp between $2 and $3" >> node10.log
mysql -u root -pqaz rpi4 -ss -e "select p14 from $1 where timestamp between $2 and $3" >> node11.log
mysql -u root -pqaz rpi4 -ss -e "select p15 from $1 where timestamp between $2 and $3" >> node12.log