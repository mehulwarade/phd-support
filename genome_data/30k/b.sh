#!/bin/sh

for index_node in $(seq 1 10); 
do
	mkdir i$index_node
	mkdir i$index_node/1
done