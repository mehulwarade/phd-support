#!/bin/sh

for workflow_size in 50
do
	mkdir output
	mkdir output/$workflow_size

	for index_node in $(seq 1 12); 
	do

		jobstate_file=$index_node'n_i'$workflow_size'_20k-jobstate.log'
		mysql_table=$index_node'n_i'$workflow_size'_20k'

		echo 'Processing: ' $jobstate_file ' using table: ' $mysql_table

		# echo 'size: ' $workflow_size ' nodes: ' $index_node
		start=$(awk '{print $1}' $index_node'n_i'$workflow_size'_20k-jobstate.log' | head -n 1)
    	end=$(awk '{print $1}' $index_node'n_i'$workflow_size'_20k-jobstate.log' | tail -n 1)

		for time in $(seq $start $end); 
		do 
			echo "File: " $jobstate_file " Time executed: " $time
			#mysql -u root -pz 20k_genome -ss -e "select * from $mysql_table where timestamp = $time" >> ../output/$workflow_size/"$mysql_table"".csv"
		done
		
		echo 'End Processing: ' $index_node'n_i'$workflow_size'_20k-jobstate.log'
	done
done
