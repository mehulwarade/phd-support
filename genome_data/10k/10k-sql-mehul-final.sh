#!/bin/sh

total_columns=14
nodes=12
individual=50

j='i50'

for i in $(seq 1 $nodes)
do
	echo $i

	jobstate_file=$i'n_i'$individual'_10k-jobstate.log'
	mysql_table=$i'n_i'$individual'_10k'

	start=$(awk '{print $1}' $j/$i/$jobstate_file | head -n 1)
	end=$(awk '{print $1}'  $j/$i/$jobstate_file | tail -n 1)

	echo Start and End >> $j/$i/extract_csv.log
	echo $start and $end >> $j/$i/extract_csv.log
	echo Extracting data ... >> $j/$i/extract_csv.log

	mysql -uroot -pz phd -ss -e "(select 'timestamp','description','p1','p2','p3','p4','p5','p6','p7','p8','p9','p10','p11','p12','p13','p14') UNION (select timestamp, description,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14 from $mysql_table where timestamp between $start and $end into outfile '/tmp/$mysql_table.csv' fields terminated by ',' lines terminated by '\r\n')"

	echo Extracting data done... ! >> $j/$i/extract_csv.log
	echo Moving file ... >> $j/$i/extract_csv.log
	echo $mysql_table: Runtime: $( expr $end - $start )  >> $j/$i/extract_csv.log
	sudo chown mehul:mehul /tmp/$mysql_table.csv
	mv /tmp/$mysql_table.csv $j/$i/

	echo nodeY,pX >> $j/$i/mapping.csv
	echo node1,p1 >> $j/$i/mapping.csv
	echo node2,p2 >> $j/$i/mapping.csv
	echo node3,p3 >> $j/$i/mapping.csv
	echo node4,p4 >> $j/$i/mapping.csv
	echo node5,p5 >> $j/$i/mapping.csv
	echo node6,p6 >> $j/$i/mapping.csv
	echo node7,p9 >> $j/$i/mapping.csv
	echo node8,p10 >> $j/$i/mapping.csv
	echo node9,p11 >> $j/$i/mapping.csv
	echo node10,p12 >> $j/$i/mapping.csv
	echo node11,p13 >> $j/$i/mapping.csv
	echo node12,p14 >> $j/$i/mapping.csv


	echo 'Processing: ' $jobstate_file
done
