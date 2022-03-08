#!/usr/bin/env perl
#
# Simple Perl-script to parse a DAG file to extract job dependencies
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon 12 Apr 2021 16:37:36 AEST
#
#########################################################################

$DEBUG = 0;

#########################################################################

# CONSTANTS - has keys
$PARENT = "PARENT";
$CHILD  = "CHILD";

# CONSTANT - Delimeter
$DEL    = ",";
$DEL2   = "_";

# CONSTANT - For output
$DASH   = "-";

#########################################################################

# 'Global' variable to keep track of parent/child dependencies
%DEPS;

# --------------------------------------------------------------------- #

# Subroutine to add a dependency between 'parent' and 'child'
sub addDependency() {

    my ($parent1, $child1) = @_;

    # Have we already recorded the 'parent' relationship?
    if ($DEPS{$parent1}{$CHILD}) {
	$DEPS{$parent1}{$CHILD} = $DEPS{$parent1}{$CHILD} . $DEL . $child1;
	
    } else {
	$DEPS{$parent1}{$CHILD} = $child1;
    }

    # Have we already recorded the 'child' relationship?
    if ($DEPS{$child1}{$PARENT}) {
	$DEPS{$child1}{$PARENT} = $DEPS{$child1}{$PARENT} . $DEL . $parent1;
	
    } else {
	$DEPS{$child1}{$PARENT} = $parent1;
    }    
    
}

# Split 'job' into a type and id... could probably be done 'better'
sub getJobTypeAndID() {

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
if (@ARGV < 1) {
    die "Insufficient input files given...";
}

my ($dag_file, @REST) = @ARGV;

#########################################################################

# Step 1 - read the DAG file and extract job dependencies
# NOTE: we are looking for 'PARENT  job CHILD job' entries

open(FH, '<', $dag_file) or die $!;

while(<FH>) {

    # Remove any end-of-line characters...
    chomp($_);
    $_ =~ s/\r|\n//g;

    my $line = $_;

    # Test for the 'PARENT  job CHILD job' pattern
    if ($line =~ m/^PARENT(\s+)(.*)(\s+)CHILD(\s+)(.*)/) {

	my $parent = $2;
	my $child  = $5;

	# Add dependency between 'parent' and 'child'
	&addDependency ($parent, $child);	
    }
}
close(FH);

# --------------------------------------------------------------------- #

# Step 2 - Print some 'header' information
my $head = "Summary information for: $dag_file";
my $len = length($head);

print $head . "\n";
for (my $i = 0; $i < $len; $i++) {
    print $DASH;
}
print "\n\n";

# --------------------------------------------------------------------- #

# Step 3 - print information about the extracted jobs and their names
%JOBS;
for $job (keys %DEPS) {
    
    # Split the job into its type
    my ($type, $id) = &getJobTypeAndID($job);

    # Increment job count...
    if ($JOBS{$type} > 0) {
	$JOBS{$type}++;
    } else {
	$JOBS{$type} = 1;
    }
}

my $no_types = ((keys %JOBS) + 0);
print "Number of jobs: " . $no_types . "\n";

for $type (sort keys %JOBS) {
    print "   " . $type . ": " . $JOBS{$type} . "\n";
}
print "\n";

# --------------------------------------------------------------------- #

# Step 4 - print information about the dependenciees between jobs

for $job (sort keys %DEPS) {

    # Print information about this job, including dependencies
    print "\njob: " . $job . "\n";

    my @parents = sort (split ($DEL, $DEPS{$job}{$PARENT}));
    my $in_degree = @parents;
    print " --> in-degree:  " . $in_degree ."\n";

    if ($in_degree > 0) {
	print "     ";
	for $val (@parents) {
	    print $val . " ";
	}
	print "\n";
    }

    my @children = sort (split ($DEL, $DEPS{$job}{$CHILD}));
    my $out_degree = @children;
    print " --> out-degree:  " . $out_degree ."\n";

    if ($out_degree > 0) {
	print "     ";
	for $val (@children) {
	    print $val . " ";
	}
	print "\n";
    }
    
}

# EOS

#########################################################################
