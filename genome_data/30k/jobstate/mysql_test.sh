#!/bin/sh

mkdir output

total_nodes=12
individual='i75'
mkdir output/$individual
cd $individual

for workflow_size in 75
do
	for index_node in $(seq 1 $total_nodes); 
	do

		jobstate_file=$index_node'n-300mb-i'$workflow_size'-jobstate.log'
		mysql_table=$index_node'n_300mb_i'$workflow_size

		echo 'Processing: ' $jobstate_file ' using table: ' $mysql_table

		# echo 'size: ' $workflow_size ' nodes: ' $index_node
		start=$(awk '{print $1}' $index_node'n-300mb-i'$workflow_size'-jobstate.log' | head -n 1)
    	end=$(awk '{print $1}' $index_node'n-300mb-i'$workflow_size'-jobstate.log' | tail -n 1)

		for time in $(seq $start $end); 
		do 
			echo "File: " jobstate_file " Time executed: " $time
			mysql -u root -pz phd -ss -e "select * from $mysql_table where timestamp = $time" >> ../output/$individual/"$mysql_table"".csv"
		done
		
		echo 'End Processing: ' $index_node'n-300mb-i'$workflow_size'-jobstate.log'
	done
done
