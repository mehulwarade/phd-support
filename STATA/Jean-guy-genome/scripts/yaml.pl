#!/usr/bin/env perl
#
# Simple Perl-script to read a YAML file (for testing purposes)
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Wed  7 Apr 2021 17:40:00 AEST
#
#########################################################################

use YAML qw(LoadFile);
use Graph;

$DEBUG = 0;

#########################################################################

# CONSTANTS - field names
$JOB_INFO = "jobs";
$ID       = "id";
$NAME     = "name";
$CHILDREN = "children";

# CONSTANT - for output
$DASH     = "-";

#########################################################################

# Subroutine to "merge" a job's id with its name
sub mergeIDName() {

    my ($id, $name) = @_;

    # return "[ $id, $name ]";
    return $name . "_" . $id;
}

#########################################################################

# Step 0 - we need 1 argument that points to a YAML file
if (@ARGV < 1) {
    die "Insufficient input files given...";
}

my ($yaml_file, @REST) = @ARGV;

#########################################################################

# 'Global' variables to keep track of id/name mappings as well as dependencies
my $graph = Graph->new; 
my %JOBS;
my %JOB_TYPES;

# --------------------------------------------------------------------- #

# Step 1 - read the YAML file and extract job information

my %data = %{ LoadFile($yaml_file) };

for my $job (@{ $data{$JOB_INFO} }) {

    # Get the 'id' and 'name' of the job
    my $id   = ${ $job }{$ID};
    my $name = ${ $job }{$NAME};

    # Record the id/name mapping of this job
    $JOBS{$id} = $name;

    # Increment the count of the job type
    if ($JOB_TYPES{$name} > 0) {
	$JOB_TYPES{$name}++;
    } else {
	$JOB_TYPES{$name} = 1;
    }

    # Add a vertex to the graph to record dependencies
    $graph->add_vertex($id);
}

# --------------------------------------------------------------------- #

# Step 2 - extract dependency information between jobs and populate graph

for my $jd (@{ $data{"jobDependencies"} }) {

    my $id   = ${ $jd }{$ID};
    my $name = $JOBS{$id};
    # print "\njob: " . &mergeIDName($id, $name) . "\n";

    my $no_children = (0 + @{ ${ $jd }{$CHILDREN}  });
    # print "children ($no_children): ";
    for $c (@{ ${ $jd }{$CHILDREN}  }) {
	
	my $m = $JOBS{$c};
	# print &mergeIDName($c, $m) . " ";

	$graph->add_edge($id, $c);
    }
    # print "\n";    
}

# --------------------------------------------------------------------- #

# Print some 'header' information
my $head = "Summary information for: $yaml_file";
my $len = length($head);

print $head . "\n";
for (my $i = 0; $i < $len; $i++) {
    print $DASH;
}
print "\n\n";

# --------------------------------------------------------------------- #

# Step 3 - print information about the extracted jobs and their names
my $no_vertices = $graph->vertices;
print "Number of jobs: " . $no_vertices . "\n";

for $type (sort keys %JOB_TYPES) {
    print "   " . $type . ": " . $JOB_TYPES{$type} . "\n";
}
print "\n";

# --------------------------------------------------------------------- #

# Step 4 - print information about the dependenciees between jobs

my $no_edges    = $graph->edges;
my @V           = sort $graph->vertices;

print "Number of dependencies: " . $no_edges . "\n";

# Iterate over all vertices, i.e. jobs
for $vertex (@V) {

    my $name = $JOBS{$vertex};

    # Print the name and id of the current vertex, i.e. job
    # NOTE: add a newline to better separate the various jobs
    print "\n";
    print "job: " . &mergeIDName($vertex, $name) . "\n";

    my $in_degree  = $graph->in_degree($vertex);
    my $out_degree = $graph->out_degree($vertex);

    # Print all incoming edges
    # NOTE: to sort them, we have to do this in two iterations...
    print " --> in-degree:  " . $in_degree ."\n";

    if ($in_degree > 0) {

	my @iJobs;
	my @edges_in = $graph->edges_to($vertex);
	
	for my $edge (@edges_in) {
	    
	    # Edges are anonymous arrays... hence we need to cast to an array
	    my @arr = @{ $edge };
	    my $from = $arr[0];
	    @iJobs = (@iJobs, $from);
	}
	
	print "     ";
	for my $id (sort @iJobs) {

	    my $name = $JOBS{$id};
	    print &mergeIDName($id, $name) . " ";
	}
	print "\n";
    }

    # Print all outgoing edges
    # NOTE: to sort them, we have to do this in two iterations...
    print " --> out-degree: " . $out_degree ."\n";
    if ($out_degree > 0) {

	my @iJobs;
	my @edges_out  = $graph->edges_from($vertex);
	
	for my $edge (@edges_out) {
	    
	    # Edges are anonymous arrays... hence we need to cast to an array
	    my @arr = @{ $edge };
	    my $to = $arr[1];
	    @iJobs = (@iJobs, $to);
	}
	
	print "     ";
	for my $id (sort @iJobs) {

	    my $name = $JOBS{$id};
	    print &mergeIDName($id, $name) . " ";
	}
	print "\n";
    }
}

# EOS

#########################################################################
