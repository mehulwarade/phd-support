#!/bin/sh

echo ====================================== >> runtime.log

for workflow_size in $(seq 75); 
do
	index_node=1

	jobstate_file=$index_node'n_i'$workflow_size'_30k-jobstate.log'
	mysql_table=$index_node'n_i'$workflow_size'_30k'

	echo 'Processing: ' $jobstate_file ' using table: ' $mysql_table

	# echo 'size: ' $workflow_size ' nodes: ' $index_node
	start=$(awk '{print $1}' $jobstate_file | head -n 1)
	end=$(awk '{print $1}' $jobstate_file | tail -n 1)

	echo $mysql_table: Runtime: $( expr $end - $start )  >> runtime.log

	echo $mysql_table: Average: >> runtime.log
	mysql -u root -pz phd -ss -e "select avg(p1) AS TOTAL FROM $mysql_table where timestamp between $start and $end" >> runtime.log
	
	echo 'End Processing: ' $index_node'n_i'$workflow_size'_20k-jobstate.log'
done


# select avg(p1) AS TOTAL FROM 1n_300mb_i25 where timestamp between 1644546415 and 1644563644;

# select avg(p1) AS TOTAL FROM 1n_300mb_i50 where timestamp between 1644500575 and 1644519588;

# select avg(p1) AS TOTAL FROM 1n_300mb_i75 where timestamp between 1644586042 and 1644607497;

# select avg(p1) AS TOTAL FROM 1n_300mb_i10 where timestamp between 1645510484 and 1645526339;