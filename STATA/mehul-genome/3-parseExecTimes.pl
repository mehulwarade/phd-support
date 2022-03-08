#!/usr/bin/env perl
#
# Simple Perl-script to parse
#
#  - a 'jobstate' log file    (first argument to script or "piped in)
#
# to tabulate the execution time for an experiment - excluding jobs on the
# host node.
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  7 Mar 2022 12:57:53 AEDT
# Works on perl v5.18.4. Check the installation on how to install or downgrade to the version
#
#########################################################################

$DEBUG = 0;

#########################################################################

# CONSTANTS - job information
$TIMESTAMP  = "AbsoluteTime";
$JOBID      = "JobID";
$JOBTYPE    = "Job";
$ID         = "ID";
$DAGMAN_ID  = "DagmanID";

# CONSTANTS - Job state state indicators
$SUBMIT        = "SUBMIT";
$EXECUTE       = "EXECUTE";
$TERMINATED    = "JOB_TERMINATED";
$SUCCESS       = "JOB_SUCCESS";
$PS_STARTED    = "POST_SCRIPT_STARTED";
$PS_TERMINATED = "POST_SCRIPT_TERMINATED";
$PS_SUCCESS    = "POST_SCRIPT_SUCCESS";

$WAIT_TIME  = "wait_time";
$EXEC_TIME  = "exec_time";
$PS_TIME    = "ps_time";

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
@WORKFLOW_JOBS = ($JOB_TYPE_1, $JOB_TYPE_2, $JOB_TYPE_3, $JOB_TYPE_4, $JOB_TYPE_5, $JOB_TYPE_6, $JOB_TYPE_7, $JOB_TYPE_8, $JOB_TYPE_9);

# Indices from the jobstate file
$TIMESTAMP_POS = 0;
$PROCESS_POS   = 1;
$STATUS_POS    = 2;
$DAGMAN_POS    = 3;
# ... remaining ones not of interest at the moment...

# Regular expression to find job based on the 'DAG Node:' entry
# NOTE: make this more 'flexible' without hardcoding the number of blanks...
$DAGNODEREGEX     = "    DAG Node: ";

# Delimeters etc.
$DEL   = '\s';
$DEL2  = "_";
$COMMA = ",";

#########################################################################

# Split 'job' into a type and id... could probably be done 'better'
sub getJobTypeAndID() {

    # Get the argument and 'declare' the two result instances
    my ($job, @REST) = @_;
    my $job_type, $job_id;

    # Let's find out how many '_' we have in '$job'
    my @SEP = split ($DEL2, $job);
    my $length = @SEP;

    # If we do not have an '_', the '$job_id' remains empty
    if ($length == 1) {
	$job_type = $SEP[0];
	$job_id   = "";

    # OK, we have more than 1 '_' and hence can split into type and id
    # NOTE: we define the job id as the information AFTER the last '_'
    } else {
	
	$job =~ /(.*)_([A-Za-z0-9_]+)/;
	$job_type = $1;
	$job_id = $2;
    }

    return ($job_type, $job_id);
}

sub getJobTypeAndID_OLD() {

    my ($job, @REST) = @_;
    my $job_type, $job_id;

    my @SEP = split ($DEL2, $job);
    my $length = @SEP;

    if ($length == 2) {
	$job_type = $SEP[0];
	$job_id   = $SEP[1];
    } elsif ($length > 2) {
	# we take the last two elements of the 'job' as id and the rest as type
	$job_id = $SEP[$length - 1] . $DEL2 . $SEP[$length - 2];
	for ($i = 0; $i < ($length - 2); $i++) {
	    $job_type = $job_type . $SEP[$i] . $DEL2;
	}
	chop $job_type;
    }

    return ($job_type, $job_id);
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

# Subroutine to find the smallest 'SUBMIT' and the largest 'EXECUTE' in hash
sub findExtremeValues($) {

    my $min_submit  = 1000000000000000000;    # some LARGE number!
    my $max_success = 0;
    my ($refHash) = @_;

    for $job (keys %{$refHash}) {

	# Minimum submit
	if ($$refHash{$job}{$SUBMIT} < $min_submit) {
	    $min_submit =$$refHash{$job}{$SUBMIT};
	}

	# Maximum success
	if ($$refHash{$job}{$SUCCESS} > $max_success) {
	    $max_success = $$refHash{$job}{$SUCCESS};
	}

	# print (keys $$refHash{$job}) . "\n";
	# print " --> " . $min_submit . ", " . $max_success . "\n";
    }

    return ($min_submit, $max_success);
}

#########################################################################

# Step 1 - Read the jobstate input and store job information in '%JOBS'
%JOBS;
my $dagman_started  = 0;
my $dagman_finished = 0;

while(<>) {

    # Remove any end-of-line characters...
    chomp($_);
    $_ =~ s/\r|\n//g;

    # Split line into fields we are interested in
    my ($timestamp, $processID, $status, $dagID, @rest) = split ($DEL, $_);

    # Let's see what process we have... check for 'SUBMIT' first...
    if ($status eq $SUBMIT) {
	$JOBS{$processID}{$SUBMIT} = $timestamp;
	$JOBS{$processID}{$DAGMAN_ID} = $dagID;
    }

    # Check for 'EXECUTE' - also check for compatible dagman IDs...
    elsif ($status eq $EXECUTE) {
	if ($JOBS{$processID}{$DAGMAN_ID} eq $dagID) {
	    $JOBS{$processID}{$EXECUTE} = $timestamp;
	} else {
	    die "Inconsistent dagman ID for $processID...";
	}
    }

    # Check for 'JOB_TERMINATED' - also check for compatible dagman IDs...
    elsif ($status eq $TERMINATED) {
	if ($JOBS{$processID}{$DAGMAN_ID} eq $dagID) {
	    $JOBS{$processID}{$TERMINATED} = $timestamp;
	} else {
	    die "Inconsistent dagman ID for $processID...";
	}
    }

    # Check for 'JOB_SUCCESS' - must have a dagman ID of '0'!!
    elsif (($status eq $SUCCESS) && ($dagID == $ZERO)) {
	$JOBS{$processID}{$SUCCESS} = $timestamp;
    }

    # Do we have an entry for 'DAGMAN_STARTED'?
    elsif ($_ =~ m/([0-9]+) INTERNAL (.*) DAGMAN_STARTED (.*)/) {
	$dagman_started = $1;
    }

    # Do we have an entry for 'DAGMAN_FINISHED'?
    elsif ($_ =~ m/([0-9]+) INTERNAL (.*) DAGMAN_FINISHED (.*)/) {
	$dagman_finished = $1;
    }
}

# --------------------------------------------------------------------- #

# Step 2 - Filter out jobs that are running on the 'host' node...
%FILTERED_JOBS;
for $job (keys %JOBS) {

    my ($job_type, $job_id) = &getJobTypeAndID($job);
    
    if (&isInList($job_type, @WORKFLOW_JOBS)) {

	# Do I really need to do this the 'hard' way?
	for $key (keys $JOBS{$job}) {
	    $FILTERED_JOBS{$job}{$key} = $JOBS{$job}{$key};
	}
    }
}

# --------------------------------------------------------------------- #

# Step 3 - get the minimum SUBMIT and maximum SUCCESS
my ($min_submit, $max_success) = &findExtremeValues(\%JOBS);
my ($min_mont_submit, $max_mont_success) = &findExtremeValues(\%FILTERED_JOBS);

# --------------------------------------------------------------------- #

# Step 4 - calcuate the relevant durations...
my $dag_time       = $dagman_finished - $dagman_started;
my $total_duration = $max_success - $min_submit;
my $work_duration  = $max_mont_success - $min_mont_submit;

#########################################################################

# Step 5 - print the relevant information...
print "DAGMAN_STARTED" . $COMMA . "DAGMAN_FINISHED";
print $COMMA . "FirstSubmit";
print $COMMA . "FirstWorkSubmit";
print $COMMA . "FinalWorkSuccess";
print $COMMA . "FinalSuccess";
print $COMMA . "dag_time" . $COMMA . "flow_time" . $COMMA . "work_time";
print "\n";

print $dagman_started . $COMMA . $dagman_finished;
print $COMMA . $min_submit;
print $COMMA . $min_mont_submit;
print $COMMA . $max_mont_success;
print $COMMA . $max_success;
print $COMMA . $dag_time . $COMMA . $total_duration . $COMMA . $work_duration;
print "\n";

# EOS

#########################################################################
