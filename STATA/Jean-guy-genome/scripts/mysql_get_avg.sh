#!/bin/sh

echo "Getting average for $1 betweeen $2 and $3"

echo $(($3-$2))

mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p1) as p1 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p2) as p2 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p3) as p3 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p4) as p4 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p5) as p5 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p6) as p6 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p9) as p9 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p10) as p10 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p11) as p11 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p12) as p12 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p13) as p13 from $1 where timestamp between $2 and $3"
mysql -u root -pqaz rpi4 -ss -e "SELECT avg(p14) as p14 from $1 where timestamp between $2 and $3"
