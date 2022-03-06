#!/bin/sh

total_columns=14
nodes=12
individual=50

j='i50'

echo ====================================== >> runtime.log

for i in $(seq 1 $nodes)
do
	echo $i

	jobstate_file=$i'n_i'$individual'_10k-jobstate.log'
	mysql_table=$i'n_i'$individual'_10k'

	start=$(awk '{print $1}' $j/$i/$jobstate_file | head -n 1)
	end=$(awk '{print $1}'  $j/$i/$jobstate_file | tail -n 1)

	echo 'Processing: ' $jobstate_file ' using table: ' $mysql_table
	
	echo $mysql_table: Runtime: $( expr $end - $start )  >> runtime.log

	if [ $i -eq 1 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	# echo $mysql_table: Average: $avg >> runtime.log
	elif [ $i -eq 2 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 3 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 4 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 5 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 6 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 7 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 8 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 9 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 10 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 11 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	elif [ $i -eq 12 ]
	then
	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13+p14) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	else
	echo haha
	fi

done
