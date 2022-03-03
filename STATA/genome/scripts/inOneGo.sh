#!/bin/sh
#
# Process the available data for a specific experiment across all nodes
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Sun 28 Mar 2021 16:52:19 AEDT
#
# Edited by: Mehul Warade <mehulwarade@gmail.com>
# Date:   Thur 3 Mar 2022 12:43:50 AEDT
############################################################################
# File structure:
# genome/
# genome/scripts/
# genome/10k/
# genome/20k/
# genome/30k/
# genome/scripts/inOneGo.sh
#

cd ../
ROOT_WORK_DIR=`pwd`

SIZE_OF_DATA="30k"
NUMBER_OF_JOBS="i25"

MAX_NODES=12


# Iteratve over all subdirectores (nodes 1-12)
for NODE_INDEX in $(seq 1 $MAX_NODES); do
	echo "Processing $NODE_INDEX..."
	cd $ROOT_WORK_DIR/$SIZE_OF_DATA/$NUMBER_OF_JOBS/$NODE_INDEX

	exit

	# Step 1 - check energy data and 'impute' where necessary
	ls -la $NODE_INDEX"n_"$NUMBER_OF_JOBS"_"$SIZE_OF_DATA"-energy.csv"
	$SCRIPTS_HOME/imputeEnergy.pl $d $DEGREES"-"$d"n.csv" > $DEGREES"-"$d"n-energy.csv"

	exit

	# Step 2 - parse the jobstate and montage logs
	ls -la "jobstate-"$DEGREES"."$d".log"
	ls -la "montage-0-"$DEGREES"."$d".log"
	$SCRIPTS_HOME/parseJobstate.pl "jobstate-"$DEGREES"."$d".log" "montage-0-"$DEGREES"."$d".log" > $DEGREES"-"$d"n-jobs.csv"

	# Step 3 - parse execution times
	$SCRIPTS_HOME/parseExecTimes.pl "jobstate-"$DEGREES"."$d".log" > $DEGREES"-"$d"n-execTimes.csv"

	# Step 4 - compute overall energy consumption
	$SCRIPTS_HOME/computeEnergy3.pl $DEGREES"-"$d"n-jobs.csv" $DEGREES"-"$d"n-energy.csv" > $DEGREES"-"$d"n-totalEnergy.csv"

	# Step 5 - illustrate the job distribution per node
	$SCRIPTS_HOME/jobsPerNode2.pl $DEGREES"-"$d"n-jobs.csv" > $DEGREES"-"$d"n-jobsPerNode.csv"
	
	# Go one level up again
	cd ..
done

# Copy some data across..
FILE=$DEGREES"-all-totalEnergy.csv"
if [ -e $FILE ] ; then
    rm $FILE
fi
touch $FILE
for d in $DIRS ; do
    if [ -d "$d" ] ; then
	cat $d"/"$DEGREES"-"$d"n-totalEnergy.csv" >> $FILE
    fi
done


############################################################################
