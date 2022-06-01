#!/usr/bin/env perl
#
# Simple Perl-script to compute energy summation data
#
# Input: two files:
#  - list of jobs (as generated by 'parseJobstate.pl')
#  - energy measurements per node (as generated by 'imputeEnergy.pl')
#
# NOTE: some copy-and-paste from a previous script :-(
# NOTE: now also includes information about the number of 'waiting' jobs
# NOTE: the energy data is 'optional' as the rest of the script works without
# NOTE: made the job types more generic
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  7 Mar 2022 16:43:38 AEDT
#
#########################################################################

use List::Util qw(min);

$DEBUG = 0;

#########################################################################

# CONSTANT - we need to divide final energy counts by this number!
$ENERGY_DIV = 3600;

# CONSTANTS - indices for the column numbers of the 'list of jobs' data
# NOTE: updated based on new 'starting time'...
$JOB            =  0;
$JOB_ID         =  1;
$DAGMAN_ID      =  2;
$NODE_IP        =  3;
$SUBMIT         =  4;
$EXECUTE        =  5;
$JOB_TERMINATED =  6;
$SUCCESS        =  7;
$PS_STARTED     =  8;
$PS_TERMINATED  =  9;
$PS_SUCCESS     = 10;
$WAIT_TIME      = 11;
$EXEC_TIME      = 12;
$PS_TIME        = 13;

# CONSTANTS - the job types of the workflow to analyze
$JOB_TYPE_1 = "frequency";
$JOB_TYPE_2 = "individuals";
$JOB_TYPE_3 = "individuals_merge";
$JOB_TYPE_4 = "mutation_overlap";
$JOB_TYPE_5 = "sifting";

# For 'future use'...
$JOB_TYPE_6 = "";
$JOB_TYPE_7 = "";
$JOB_TYPE_8 = "";
$JOB_TYPE_9 = "";

# The list of workflow jobs in an array (for easier processing)
# NOTE: this should somewhat go into a configuration file -> ToDo
# NOTE: we will prune 'empty' job types as part of the script
@JOB_TYPES_ALL = ($JOB_TYPE_1, $JOB_TYPE_2, $JOB_TYPE_3, $JOB_TYPE_4, $JOB_TYPE_5, $JOB_TYPE_6, $JOB_TYPE_7, $JOB_TYPE_8, $JOB_TYPE_9);

# CONSTANTS - indices for the column numbers of the 'energy' data
$E_TIMSTAMP     = 0;
$E_TIME         = 1;             # not really used any more...
$E_TOTAL_ENERGY = 2;
$E_NODE_1       = 3;
# NOTE: '$E_NODE_2 = E_NODE_1 + 1', 'E_NODE_3 = E_NODE_2 + 1' etc.

# --------------------------------------------------------------------- #

# CONSTANTS - for output
$DURATION      = "Jobs_Exec_Time";
$TOTAL_ENERGY  = "Total_Energy";
$ENERGY_SAVING = "Energy_Saving";
$CALCULATION   = "Calculation";
$OVERALL       = "Overall";
$NODE_BASIS    = "NodeBasis";

$FIRST_WAITING = "FirstSubmit";
$FINAL_SUCCESS = "FinalSuccess";

# CONSTANTS - various delimeteres
$DEL         = ",";

#########################################################################

# The list of collected Node IPs
my %NODE_IPs;

#########################################################################

# Subroutine to get the '$index' value of a comma-separated list
sub getValue() {
    my ($index, $aRow) = @_;
    my @values = split($DEL, $aRow);
    return @values[$index];
}

# Subroutine to create a new job_id as a merge of other information
sub getNewJobID() {
    my ($node_ip, $type, $job_id) = @_;
    return "$node_ip$SEP$type$SEP$job_id";
}

# Subroutine to get the job type of what has been created by 'getNewJobID'
sub getJobType() {
    my ($job_id, @rest) = @_;
    my @job_split = split($SEP, $job_id);
    return $job_split[1];
}

# Subroutine to get the Node IP what has been created by 'getNewJobID'
sub getJobNodeIP() {
    my ($job_id, @rest) = @_;
    my @job_split = split($SEP, $job_id);
    return $job_split[0];
}

# Subroutine to test 'list' membership
sub isInList() {

    my ($element, @LIST) = @_;
    my $result = 0;

    for $val (@LIST) {
	if ($val eq $element) {
	    $result = 1;
	    break;
	}
    }
    
    return $result;
}

#########################################################################

# Step 0 - parse the command-line arguments. We need at least one input file...
if (@ARGV < 1) {
    die "Insufficient input files give...";
}

my $job_data = "";
my $energy_data = "";
($job_data, $energy_data) = @ARGV;

# As a pre-processing step, we also need to filter out 'empty' job types
# from '@JOB_TYPES_ALL'
@JOB_TYPES;
my $index = 0;
foreach $val (@JOB_TYPES_ALL) {
    if ($val) {
	@JOB_TYPES[$index] = $val;
	$index++;
    }
}

#########################################################################

# Step 1 - Read the 'job data' in 'one go' and store in '@JOB_DATA'
my $line = 0;
my $header = 1;
my @JOB_DATA;

# lets also collect the maximum and minimum time stamps
$min_submit     = 100000000000;      # large number to begin with :-)
$min_exec       = 100000000000;      # large number to begin with :-)
$max_success    = 0;

# Open the 'job data' file and read its contents.
open (JDFH, '<', $job_data) or die $!;
while(<JDFH>) {

    # Remove trailing newline character(s)
    chomp($_);
    $_ =~ s/\r|\n//g;

    # We are not interested in the header row... there may be a more elegant way...
    if ($header) {
	$header = 0;

    # Process the rest of the job data input
    } else {

	# Filter out any 'jobs' we are not interested in.
	my $job_type = &getValue($JOB, $_);

	# We only record Montage jobs...
	if (&isInList($job_type, @JOB_TYPES)) {

	    $JOB_DATA[$line] = $_;
	    $line++;

	    # Update the hash with the Node IPs for all Montage jobs
	    my $node_ip = &getValue($NODE_IP, $_);
	    $NODE_IPs{$node_ip} = 1;

	    # Update the maximum and minimum time stamps
	    # NOTE: a job 'waits' from 'SUBMIT' to 'EXECUTE' (not included)
	    my $timestamp = &getValue($SUBMIT, $_);
	    if ($timestamp && ($timestamp < $min_submit)) {
		$min_submit = $timestamp
	    }

	    # NOTE: a job 'runs' from 'EXECUTE' to 'SUCCESS'
	    $timestamp = &getValue($EXECUTE, $_);
	    if ($timestamp && ($timestamp < $min_exec)) {
		$min_exec = $timestamp
	    }
	    $timestamp = &getValue($SUCCESS, $_);
	    if ($timestamp && ($timestamp > $max_success)) {
		$max_success = $timestamp
	    }
	}
    }
}
close(JDFH);

# --------------------------------------------------------------------- #

# Step 2 - read the energy data (if available)
my %ENERGY_DATA;
$header = 1;
my $energy_head;

# Open the 'energy data' file (if available) and read its contents.
if (open (EDFH, '<', $energy_data)) {
    while(<EDFH>) {

	# Remove trailing newline character(s)
	chomp($_);
	$_ =~ s/\r|\n//g;

	# Parse the header row... and extract IP addresses
	# NOTE: if not all IP addresses execute jobs, then they do not appear
	#       in the first input file and hence need to be added...
	if ($header) {
	    $energy_head = $_;
	    $header = 0;

	    # Iterate over all IP addresses we have energy data for...
	    my (@HDATA) = split ($DEL, $_);
	    for ($node_index = $E_NODE_1; $node_index < @HDATA; $node_index++) {    
		$NODE_IPs{$HDATA[$node_index]} = 1;
	    }

	# Parse the remaining rows of energy data
	} else {

	    my $row = $_;
	    my @VALUES = split ($DEL, $row);
	    
	    my $e_timestamp  = @VALUES[$E_TIMSTAMP];
	    my $total_energy = @VALUES[$E_TOTAL_ENERGY];

	    # Iterate over the energy data of each node, add to energy data
	    my $total_energy = 0;
	    for ($index = $E_NODE_1; $index < @VALUES; $index++) {

		# Get the energy data for the node and increment total energy
		my $node_energy_data = $VALUES[$index];
		$total_energy += $node_energy_data;

		# What is 'index' node ip? We have this information in header
		my $node_ip = &getValue($index, $energy_head);

		# Update energy data for 'node_ip' at timestamp 'e_timestamp'
		$ENERGY_DATA{$node_ip}{$e_timestamp} = $node_energy_data;
	    }
	}
    }
    close(EDFH);
}

# --------------------------------------------------------------------- #

# Step 3 - order the collected Node IPs
# NOTE: the value stored under a particular Node IP represents its Node number
my $count = 1;
for $ip (sort keys %NODE_IPs) {
    $NODE_IPs{$ip} = $count;
    $count++;
}

# --------------------------------------------------------------------- #

# Step 4 - record when each job is 'waiting' and when 'executing'
# NOTE: we do this on a per node basis
my %WAITING;
my %EXECUTE;
my %MAX_SUCCESS;

# Initialize 'MAX_SUCCESS'
for $ip (keys %NODE_IPs) {
    $MAX_SUCCESS{$ip} = 0;
}

for $job_info (@JOB_DATA) {

    # Get information about the current job
    my @VALUES = split ($DEL, $job_info);
    
    # We only need the following four values for each job
    my $node_ip  = $VALUES[$NODE_IP];
    my $submit   = $VALUES[$SUBMIT];
    my $execute  = $VALUES[$EXECUTE];
    my $success  = $VALUES[$SUCCESS];

    # Record the current job as 'wating' from 'submit' to 'execute-1'
    # Note: we do not record the specific job types waiting, just the total
    for (my $time_stamp = $submit; $time_stamp < $execute; $time_stamp++) {

	if ($WAITING{$node_ip}{$time_stamp}) {
	    $WAITING{$node_ip}{$time_stamp}++;
	} else {
	    $WAITING{$node_ip}{$time_stamp} = 1;
	}
    }

    # Record the current job as executing from 'execute' to 'success'
    for (my $time_stamp = $execute; $time_stamp <= $success; $time_stamp++) {

	if ($EXECUTE{$node_ip}{$time_stamp}) {
	    $EXECUTE{$node_ip}{$time_stamp}++;
	} else {
	    $EXECUTE{$node_ip}{$time_stamp} = 1;
	}
    }

    # Update the max. 'SUCCESS' for 'node_ip' (if needed)
    if ($MAX_SUCCESS{$node_ip} < $success) {
	$MAX_SUCCESS{$node_ip} = $success;
    }
}

# DEBUGGING
if ($DEBUG > 0) {
    $st = min (($min_submit, $min_exec));
    for $ip (sort keys %NODE_IPs) {
	print $ip . ", " . $st . ", " . $MAX_SUCCESS{$ip};
	if ($MAX_SUCCESS{$ip} > 0) {
	    print ", " . ($MAX_SUCCESS{$ip} - $st);
	}
	print "\n";
    }
    print "\n";
}

# --------------------------------------------------------------------- #

# Print the energy data (for testing)
if ($DEBUG > 0) {
    for ($ts = $min_exec - 1; $ts <= $max_success + 1; $ts++) {

	for $node (sort keys %NODE_IPs) {
	    print $DEL . "$node : $ENERGY_DATA{$node}{$ts}";
	}
	print "\n";
    }
}

# Print the 'waiting' data...
if ($DEBUG > 0) {
    print "\nWaiting information... \n";
    for $ts (sort keys %WAITING) {
	for $ip (sort keys $WAITING{$ts}) {
	    print $ts . $DEL . $ip;
	    print $DEL . $WAITING{$ip}{$ts} . "\n";
	}
    }
    exit 0;
}

# --------------------------------------------------------------------- #

# Step 5 - calculate the total energy on a per node basis and add up
my %NODE_ENERGY;
for $ip (keys %NODE_IPs) {
    $NODE_ENERGY{$ip} = 0;
}
my $total_energy = 0;

# Calculation 1 - we calculate the energy from the first recorded 'SUBMIT'
#                 to the last recorded 'SUCCESS' across ALL nodes
my $start_time = min (($min_submit, $min_exec));
for (my $ts = $start_time; $ts <= $max_success; $ts++) {

    # Iterate over all nodes
    for $ip (keys %NODE_IPs) {

	# Add the node's energy at timestamp 'ts' to the overall energy
	if ($NODE_ENERGY{$ip}) {
	    $NODE_ENERGY{$ip} += $ENERGY_DATA{$ip}{$ts};
	} else {
	    $NODE_ENERGY{$ip} = $ENERGY_DATA{$ip}{$ts};
	}

	$total_energy += $ENERGY_DATA{$ip}{$ts};
    }
}

# DEBUGGING
if ($DEBUG) {
    for $ip (sort keys %NODE_IPs) {
	print $ip . ", " . $NODE_ENERGY{$ip} . "\n";
    }
    print "\n";
}

# --------------------------------------------------------------------- #

# Step 6 - print the summary information... by node number
# Create and print header row
my $head = $CALCULATION . $DEL . $FIRST_WAITING . $DEL . $FINAL_SUCCESS;
$head .= $DEL . $DURATION . $DEL . $TOTAL_ENERGY;
$head .= $DEL . $ENERGY_SAVING;
for $node_id (sort keys %NODE_ENERGY) {
    $head .= $DEL . $node_id;
}
print $head . "\n";

# Print result of 'overall' energy calculation
print $OVERALL;
print $DEL . $start_time;
print $DEL . $max_success;
print $DEL . ($max_success - $start_time);
printf("$DEL %.4f", ($total_energy / (1.0 * $ENERGY_DIV)));
printf("$DEL %.4f", ($total_energy / (1.0 * $total_energy)));
for $node (sort keys %NODE_ENERGY) {
    printf ("$DEL %.4f", ($NODE_ENERGY{$node} / (1.0 * $ENERGY_DIV)));
}
print "\n";

# --------------------------------------------------------------------- #

# Calculation 2 - we calculate the energy from the first recorded 'SUBMIT'
#                 to the last recorded 'SUCCESS' on a node by node basis
# NOTE: we need to reset the energy values first!
for $node_id (keys %NODE_ENERGY) {
    $NODE_ENERGY{$node_id} = 0;
}

# Keep a record of the overall energy used... and then clear.
$all_energy = $total_energy;
$total_energy = 0;

# Iterate over all nodes
for $ip (keys %NODE_IPs) {

    # Iterate until we reach the max. 'SUCCESS' for this node
    for (my $ts = $start_time; $ts <= $MAX_SUCCESS{$ip}; $ts++) {

	# Add the node's energy at timestamp 'ts' to the overall energy
	if ($NODE_ENERGY{$ip}) {
	    $NODE_ENERGY{$ip} += $ENERGY_DATA{$ip}{$ts};
	} else {
	    $NODE_ENERGY{$ip} = $ENERGY_DATA{$ip}{$ts};
	}

	$total_energy += $ENERGY_DATA{$ip}{$ts};
    }
}

# Print result of 'node-basis' energy calculation
print $NODE_BASIS;
print $DEL . $start_time;
print $DEL . $max_success;
print $DEL . ($max_success - $start_time);
printf("$DEL %.4f", ($total_energy / (1.0 * $ENERGY_DIV)));
printf("$DEL %.4f", ($total_energy / (1.0 * $all_energy)));
for $node (sort keys %NODE_ENERGY) {
    printf ("$DEL %.4f", ($NODE_ENERGY{$node} / (1.0 * $ENERGY_DIV)));
}
print "\n";

# EOS

#########################################################################