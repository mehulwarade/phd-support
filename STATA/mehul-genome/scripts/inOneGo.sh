#!/bin/sh
#
# Process the available data for a specific experiment across all nodes
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Sun 28 Mar 2021 16:52:19 AEDT
#
# Edited By: Mehul Warade
# Date: Thur 10 Mar 2022 12:01:20 AEDT
#
#  - folder name - 12n_i50_30k / 6n_i50_10k    (first argument to script)
#  - number of nodes being used - 12 / 6       (second argument to script)
#
############################################################################
# using perl 5.18.4 binary in the folder
# perlbrew: 
# 	curl -L http://xrl.us/installperlosx | bash
# install specific version of perl: 
#	perlbrew install 5.18.4
# Install dir: ~/perl5/perlbrew/build/perl-5.18.4/perl-5.18.4
############################################################################


DATA_FOLDER=$1
NUMBER_OF_NODES=$2

SCRIPT0=0-parseEnergy
SCRIPT1=1-imputeEnergy2
SCRIPT2=2-parseJobstate
SCRIPT3=3-parseExecTimes
SCRIPT4=4-computeEnergy3
SCRIPT5=5-jobsPerNode2
SCRIPT6=6-allPerTimePerNode5

SCRIPTS_HOME=`pwd`

echo "Processing $DATA_FOLDER..."
cd ../$DATA_FOLDER
mkdir output

# Step 0 - check energy data and 'impute' where necessary

$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT0.pl $DATA_FOLDER.csv mapping.csv > output/$SCRIPT0-output.csv

# Step 1 - check energy data and 'impute' where necessary
$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT1.pl $NUMBER_OF_NODES output/$SCRIPT0-output.csv > output/$SCRIPT1-output.csv

# Step 2 - parse the jobstate and montage logs
$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT2.pl $DATA_FOLDER"-jobstate.log" $DATA_FOLDER"-1000-genome-0.log" > output/$SCRIPT2-output.csv

# Step 3 - parse execution times
$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT3.pl $DATA_FOLDER"-jobstate.log" > output/$SCRIPT3-output.csv

# Step 4 - compute overall energy consumption
$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT4.pl output/$SCRIPT2-output.csv output/$SCRIPT1-output.csv > output/$SCRIPT4-output.csv

# Step 5 - illustrate the job distribution per node
$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT5.pl output/$SCRIPT2-output.csv > output/$SCRIPT5-output.csv

# Step 6 - allow us to plot jobs on a per-node basis
$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT6.pl output/$SCRIPT2-output.csv output/$SCRIPT1-output.csv > output/$SCRIPT6-output.csv

############################################################################
