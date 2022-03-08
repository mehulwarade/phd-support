#!/usr/bin/env perl
#
# Simple Perl-script to summarize the number of jobs per node
#
# Input
#  - a 'jobs' file    (first argument to script or "piped in)
#    => output of the 'parseJobstate' script
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  7 Mar 2022 14:01:07 AEDT
#
#########################################################################

$DEBUG = 0;

#########################################################################

# CONSTANTS - indices for the various column numbers
# NOTE: updated based on new 'starting time'...
# NOTE: for future reference, we may want to determine the column headers
#       dynamically to reduce dependencies on precise column numbers!
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
@JOB_TYPES = ($JOB_TYPE_1, $JOB_TYPE_2, $JOB_TYPE_3, $JOB_TYPE_4, $JOB_TYPE_5, $JOB_TYPE_6, $JOB_TYPE_7, $JOB_TYPE_8, $JOB_TYPE_9);

# CONSTANTS - for hear row:
$NODE_IP_HEAD = "NodeIP";
$NODE_ID_HEAD = "NodeID";

$DEL = ",";

#########################################################################

# Subroutine to get the '$index' value of a comma-separated list
sub getValue() {
    my ($index, $aLine) = @_;
    my @values = split(',', $aLine);
    return @values[$index];
}

#########################################################################

# Step 1 - Read the input in 'one go' and store in '@LINES'
$line = 0;
$header = 1;
@LINES;

while(<>) {
    chop $_;

    # We are not interested in the header line... there may be a more elegant way...
    if ($header) {
	$header = 0;
    } else {
	$LINES[$line] = $_;
	$line++;
    }
}

# Some debugging...
if ($DEBUG) {
    print "Number of lines read (excluding header): " . $line . "\n";
    print @LINES[$line -1] . "\n";
    print &getValue(1, @LINES[$line -1]) . "\n";
    print &getValue(5, @LINES[$line -1]) . "\n";
}

# -------------------------------------------------------------------------- #

# Step 2 - Iterate over all lines and increment process information
%JOBS;
for $line (@LINES) {

    # get the job description and node id from '$line'
    my $job     = &getValue($JOB, $line);
    my $node_ip = &getValue($NODE_IP, $line);

    # print " ---> " . $node_ip . " - " . $job . "\n";

    if ($JOBS{$node_ip}{$job}) {
	$JOBS{$node_ip}{$job} = $JOBS{$node_ip}{$job} + 1;
	# print " --> added: " . $JOBS{$node_ip}{$job} . "\n";
    } else {
	$JOBS{$node_ip}{$job} = 1;
    }
}

# Some debugging
if ($DEBUG) {
    for $iNode (sort keys %JOBS) {
	printf ("%s: ", $iNode);
	for $type ( keys %{ $JOBS{$iNode} } ) {
	    my $cVal = $JOBS{$iNode}{$type};
	    printf ("%s = %d  ", $type, $cVal);
	    #print "$type=$JOBS{$iNode}{$type} ";
	}
	print "\n";
    }
}

# -------------------------------------------------------------------------- #

# Step 3 - print the summary information...
# NOTE: filter out 'empty' job types
$head = $NODE_IP_HEAD . $DEL . $NODE_ID_HEAD;
for $type (@JOB_TYPES) {

    # Filter out 'empty' job types names...
    if ($type) {
	$head = $head . $DEL . $type;
    }
}
print $head . "\n";

$node_id = -1;
for $iNode (sort keys %JOBS) {

    # We (somewhat) have an 'empty' iNode here - filter out...
    if ($iNode) {

	# Increment 'node_id'
	$node_id++;

	# Print the node id
	printf ("%s$DEL%d", $iNode, $node_id);
	
	# iterate over all jobs
	for $type (@JOB_TYPES) {

	    # Filter out 'empty' job types names...
	    if ($type) {
		# print "" . $type . " - ";
		# printf ("%d ", $iNode);
		# print " - ";

		print ", ";
		if ($JOBS{$iNode}{$type}) {
		    print $JOBS{$iNode}{$type};
		} else {
		    print "0";
		}
	    }
	}
	print "\n";
    }
}

# -------------------------------------------------------------------------- #

# Step 4 - print 'another' way...
print "\n";
$head = $NODE_IP_HEAD . ", JobType, Count";
print $head . "\n";
for $iNode (sort keys %JOBS) {

    # We (somewhat) have an 'empty' iNode here - filter out...
    if ($iNode) {

	# iterate over all jobs
	for $type (@JOB_TYPES) {

	    # Filter out 'empty' job types names...
	    if ($type) {
		
		my $count = 0;
		if ($JOBS{$iNode}{$type}) {
		    $count = $JOBS{$iNode}{$type};
		}
		printf ("%s,%s,%d\n", $iNode, $type, $count);
	    }
	}
    }
}

# EOS

#########################################################################
