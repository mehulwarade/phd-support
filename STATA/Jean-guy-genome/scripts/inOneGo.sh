#!/bin/sh
#
# Process the available data for a specific experiment across all nodes
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Sun 28 Mar 2021 16:52:19 AEDT
#
############################################################################

SCRIPTS_HOME="/Users/jeanguy.schneider/Desktop/FINAL_ALL_DATA/scripts"

DEGREES="1.5"

############################################################################
# Get all the sub-directories
DIRS="`ls | sort -n`"

# Iteratve over all subdirectores
for d in $DIRS ; do

    if [ -d "$d" ] ; then
	echo "Processing $d..."
	cd $d

	# Step 1 - check energy data and 'impute' where necessary
	ls -la $DEGREES"-"$d"n.csv"
	$SCRIPTS_HOME/imputeEnergy2.pl $d $DEGREES"-"$d"n.csv" > $DEGREES"-"$d"n-energy.csv"

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
    fi
       
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
