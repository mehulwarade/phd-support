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

NUMBER_OF_NODES=$1

SCRIPT=montage_scheduler_computeEnergy

SCRIPTS_HOME=`pwd`

echo 'Processing: '$NUMBER_OF_NODES'n_i50_20k'
echo 'Processing: '$NUMBER_OF_NODES'n_i50_20k' >> $SCRIPTS_HOME/new_energy_compute.csv

$SCRIPTS_HOME/./perl $SCRIPTS_HOME/$SCRIPT.pl ../$NUMBER_OF_NODES/'1-'$NUMBER_OF_NODES'n-jobs.csv' ../$NUMBER_OF_NODES/'1-'$NUMBER_OF_NODES'n-energy.csv' >> $SCRIPTS_HOME/new_energy_compute.csv
echo ''>> $SCRIPTS_HOME/new_energy_compute.csv