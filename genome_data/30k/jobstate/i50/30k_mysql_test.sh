#!/bin/sh

for workflow_size in 50
do
	mkdir output
	mkdir output/$workflow_size
	cd $workflow_size
	echo ====================================== >> runtime.log

	for index_node in $(seq 1 12); 
	do

		jobstate_file=$index_node'n-300mb-i'$workflow_size'-jobstate.log'
		mysql_table=$index_node'n_300mb_i'$workflow_size

		echo 'Processing: ' $jobstate_file ' using table: ' $mysql_table

		# echo 'size: ' $workflow_size ' nodes: ' $index_node
		start=$(awk '{print $1}' $jobstate_file | head -n 1)
    	end=$(awk '{print $1}' $jobstate_file | tail -n 1)

		echo $mysql_table: Runtime: $( expr $end - $start )  >> runtime.log

		if [ $index_node -eq 1 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		# echo $mysql_table: Average: $avg >> runtime.log
		elif [ $index_node -eq 2 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 3 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 4 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 5 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 6 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 7 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 8 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 9 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 10 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 11 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		elif [ $index_node -eq 12 ]
		then
		mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13+p14) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
		else
		echo haha
		fi
		# echo Command: select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13+p14) 

		# for time in $(seq $start $end); 
		# do 
		# 	echo "File: " $jobstate_file " Time executed: " $time
		# 	mysql -u root -pz phd -ss -e "select * from $mysql_table where timestamp = $time" >> output/$workflow_size/"$mysql_table"".csv"
		# done
		
		echo 'End Processing: ' $index_node'n_i'$workflow_size'_20k-jobstate.log'
	done
done
