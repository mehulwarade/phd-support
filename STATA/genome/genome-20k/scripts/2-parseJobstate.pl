#!/usr/bin/env perl
#
# Simple Perl-script to parse
#
#  - a 'jobstate' log file    (first argument to script)
#  - a 'montage' log file     (second argument to script)
#
# to tabulate job information
# NOTE: extracted some more jobstate information
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  7 Mar 2022 12:57:53 AEDT
#
#########################################################################

$DEBUG = 0;

#########################################################################

# CONSTANTS - job information
$TIMESTAMP  = "AbsoluteTime";
$JOBID      = "JobID";
$JOBTYPE    = "Job";
$ID         = "ID";
$DAGMAN     = "DAGMAN";
$DAGMAN_ID  = "DagmanID";
$INTERNAL   = "INTERNAL";

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

# CONSTANTS - the job types --> not needed in this script!!

# Indices from the jobstate file
$TIMESTAMP_POS = 0;
$PROCESS_POS   = 1;
$STATUS_POS    = 2;
$DAGMAN_POS    = 3;
# ... remaining ones not of interest at the moment...

$NODE_NUMBER     = "Node ID";
$NODE_IP_ADDRESS = "Node IP";

# Regular expression to find job based on the 'DAG Node:' entry
# NOTE: make this more 'flexible' without hardcoding the number of blanks...
$DAGNODEREGEX    = "    DAG Node: ";
$JOBEXECUTEREGEX = "Job executing on host: ";

# Delimeters etc.
$DEL   = '\s';
$COMMA = ",";
$ZERO  = "0";
$DEL2  = "_";

#########################################################################

# Subroutine to print debugging information (only if '$DEBUG' is not 0)
sub printDebugInfo() {
    my ($text, @REST) = @_;
    if ($DEBUG) {
	print $text;
    }
}

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

    if ($length == 1) {
	$job_type = $SEP[0];
	$job_id   = "";
    } elsif ($length == 2) {
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

#########################################################################

# Step 0 - command-line arguments...
my ($jobStateFile, $montageFile) = @ARGV;

if (!(($jobStateFile) && ($montageFile))) {
    die "Insuficient command-line arguments given...";
}

#########################################################################

# Step 1 - Read the jobstate input and store job information in '%JOBS'
&printDebugInfo ("Reading " . $jobStateFile . "...");
%JOBS;
my $dagman_started  = 0;
my $dagman_finished = 0;
my $dagman_id       = "";

open(FH, '<', $jobStateFile) or die $!;
while(<FH>) {

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
    elsif (($status eq $SUCCESS) && ($dagID eq $ZERO)) {
	$JOBS{$processID}{$SUCCESS} = $timestamp;
    }

    # Check for 'POST_SCRIPT_STARTED' - also check for compatible dagman IDs...
    elsif ($status eq $PS_STARTED) {
	if ($JOBS{$processID}{$DAGMAN_ID} eq $dagID) {
	    $JOBS{$processID}{$PS_STARTED} = $timestamp;
	} else {
	    die "Inconsistent dagman ID for $processID...";
	}
    }

    # Check for 'POST_SCRIPT_TERMINATED' - also check for compatible dagman IDs...
    elsif ($status eq $PS_TERMINATED) {
	if ($JOBS{$processID}{$DAGMAN_ID} eq $dagID) {
	    $JOBS{$processID}{$PS_TERMINATED} = $timestamp;
	} else {
	    die "Inconsistent dagman ID for $processID...";
	}
    }

    # Check for 'POST_SCRIPT_SUCCESS' - must have a dagman ID of '0'!!
    elsif (($status eq $PS_SUCCESS) && ($dagID eq $ZERO)) {
	$JOBS{$processID}{$PS_SUCCESS} = $timestamp;
    }

    # Do we have an entry for 'DAGMAN_STARTED'?
    elsif ($_ =~ m/([0-9]+) INTERNAL (.*) DAGMAN_STARTED ([0-9]+\.[0-9]+) (.*)/) {
	$dagman_started = $1;
	$dagman_id      = $3;
    }

    # Do we have an entry for 'DAGMAN_FINISHED'?
    elsif ($_ =~ m/([0-9]+) INTERNAL (.*) DAGMAN_FINISHED (.*)/) {
	$dagman_finished = $1;
    }
}
close(FH);
&printDebugInfo (" done\n");

# --------------------------------------------------------------------- #

# Step 2 - calcuate wait-, execute- and postscript- times
&printDebugInfo ("Calculating wait- and execution times...");
for $job (keys %JOBS) {
    
    my $wait_time = $JOBS{$job}{$EXECUTE} - $JOBS{$job}{$SUBMIT};
    my $exec_time = $JOBS{$job}{$SUCCESS} - $JOBS{$job}{$EXECUTE};
    my $ps_time   = $JOBS{$job}{$PS_SUCCESS} - $JOBS{$job}{$PS_STARTED};

    $JOBS{$job}{$WAIT_TIME} = $wait_time;
    $JOBS{$job}{$EXEC_TIME} = $exec_time;
    $JOBS{$job}{$PS_TIME}   = $ps_time;
}
&printDebugInfo (" done\n");

# --------------------------------------------------------------------- #

# Step 3 - read the montage log in 'one go' and store in '@LINES'
# NOTE: this could probably be done a bit more effectively, but may do for now
&printDebugInfo ("Reading " . $montageFile . "...");
@LINES;
my $index = 0;
open(FH, '<', $montageFile) or die $!;
while(<FH>) {

    # Remove any end-of-line characters...
    chomp($_);
    $_ =~ s/\r|\n//g;

    # Read each inline into the '@LINES' array
    $LINES[$index] = $_;
    $index++;
}
close(FH);
&printDebugInfo (" done\n");

# --------------------------------------------------------------------- #

# Step 4 - get the "full" Dagman ID for each job
&printDebugInfo ("Getting Dagman ID for each job...");
for ($i = 0; $i < @LINES; $i++) {

    # Get the 'i-th' line
    my $line = $LINES[$i];

    # Do we have a line that matches 'Dag Node:?
    if ($line =~ m/$DAGNODEREGEX(.*)/) {
	
	# The 'job' is the first sub-expression
	my $job = $1;

	# The line before will give us the "full" Dagman ID
	my $lineBefore = $LINES[$i-1];

	if ($lineBefore =~ m/(.*) \((.*)\) (.*)/) {

	    # Update '%JOBS' with the "full" Dagman ID
	    my $dagman_id = $2;
	    $JOBS{$job}{$DAGMAN_ID} = $dagman_id;

	    &printDebugInfo (" --> processing:" . $line . "\n");
	    &printDebugInfo ("     --> " . $lineBefore . "\n");
	    &printDebugInfo ("     --> " . $dagman_id . "\n");
	}	
    }
}
&printDebugInfo (" done\n");

# --------------------------------------------------------------------- #

# Step 5 - get the IP address for each job from the montage log...
&printDebugInfo ("Getting IP address for each job...");
for $line (@LINES) {

    # Match for 'Job executing on host: '...
    if ($line =~ m/[0-9]+ \((.*)\) (.*)($JOBEXECUTEREGEX)(.*)/) {

	# The 'url' (that includes the IP address) is the fourth sub-rexpression
	my $url = $4;
	my $dagman_id = $1;

	# We want the IP4 address directly following a '<'
	if ($url =~ m/(.)(.*)\:(.)/) {

	    my $ip_address = $2;

	    # -> need to get the right job number for the ip_address!!!
	    # NOTE: for now, do a 'backwards search' in '%JOBS'
	    #       this could be more efficient but not sure how...
	    for $job (keys %JOBS) {

		if ($JOBS{$job}{$DAGMAN_ID} eq $dagman_id) {
		    $JOBS{$job}{$NODE_IP_ADDRESS} = $ip_address;

		    &printDebugInfo (" ---> " . $dagman_id . " --> " . $ip_address . "\n");
		}
		break;
	    }
	}	
    }
}
&printDebugInfo (" done\n");

# --------------------------------------------------------------------- #

# Step 6 - add Dagman start and end times...
# NOTE: we are 'misusing' a couple of columns here!
$JOBS{$DAGMAN}{$DAGMAN_ID}  = $dagman_id;
$JOBS{$DAGMAN}{$SUBMIT}     = $dagman_started;
$JOBS{$DAGMAN}{$PS_SUCCESS} = $dagman_finished;

#########################################################################

# Step 7 - print what we have... and split 'job' into a type and id...
print $JOBTYPE. $COMMA . $ID . $COMMA . $DAGMAN_ID;
print $COMMA . $NODE_IP_ADDRESS;
print $COMMA . $SUBMIT;
print $COMMA . $EXECUTE . $COMMA . $TERMINATED . $COMMA . $SUCCESS;
print $COMMA . $PS_STARTED . $COMMA . $PS_TERMINATED . $COMMA . $PS_SUCCESS;
print $COMMA . $WAIT_TIME . $COMMA . $EXEC_TIME . $COMMA . $PS_TIME;
print "\n";

# Iterate over all jobs that were extracted...
for $job (keys %JOBS) {

    # Split 'job' into a type and id... could probably be done 'better'
    my ($job_type, $job_id) = &getJobTypeAndID($job);
    print $job_type . $COMMA . $job_id;
    print $COMMA . $JOBS{$job}{$DAGMAN_ID};
    print $COMMA . $JOBS{$job}{$NODE_IP_ADDRESS};

    print $COMMA . $JOBS{$job}{$SUBMIT};
    print $COMMA . $JOBS{$job}{$EXECUTE};
    print $COMMA . $JOBS{$job}{$TERMINATED};
    print $COMMA . $JOBS{$job}{$SUCCESS};
    print $COMMA . $JOBS{$job}{$PS_STARTED};
    print $COMMA . $JOBS{$job}{$PS_TERMINATED};
    print $COMMA . $JOBS{$job}{$PS_SUCCESS};
    
    print $COMMA . $JOBS{$job}{$WAIT_TIME};
    print $COMMA . $JOBS{$job}{$EXEC_TIME};
    print $COMMA . $JOBS{$job}{$PS_TIME};    
    
    print "\n";
}

# EOS

#########################################################################
