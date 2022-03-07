#!/bin/sh

total_columns=14
nodes=12
individual=50

j='i50'

echo ====================================== >> energy.log

for index_node in $(seq 1 $nodes); 
do

	jobstate_file=$index_node'n_i'$individual'_20k-jobstate.log'
	mysql_table=$index_node'n_i'$individual'_20k'

	echo 'Processing: ' $jobstate_file ' using table: ' $mysql_table

	start=$(awk '{print $1}' $j/$index_node/$jobstate_file | head -n 1)
	end=$(awk '{print $1}' $j/$index_node/$jobstate_file | tail -n 1)

	echo $mysql_table: Runtime: $( expr $end - $start )  >> energy.log

	mysql -u root -pz phd -ss -e "select avg(p1+p2+p3+p4+p5+p6+p9+p10+p11+p12+p13+p14) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> energy.log
	
	echo 'End Processing: ' $index_node'n_i'$workflow_size'_20k-jobstate.log'
done
