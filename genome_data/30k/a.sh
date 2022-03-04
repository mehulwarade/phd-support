#!/bin/sh

individual='i75'

for index_node in $(seq 1 12); 
do
	cp jobstate/$individual/$index_node'n-300mb-'$individual'-jobstate.log' $individual/$index_node/$index_node'n_'$individual'_30k-jobstate.log'

	cp genome-o.log/$individual/$index_node'n-300mb-'$individual'-1000-genome-0.log' $individual/$index_node/$index_node'n_'$individual'_30k-1000-genome-0.log'
done