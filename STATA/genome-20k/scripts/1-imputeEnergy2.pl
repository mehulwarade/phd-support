#!/usr/bin/env perl
#
# Simple Perl-script to 'impute' missing data points from energy measurements
#
# Arguments:
#  - the number of nodes to consider (value between 1 to 12)
#  - the '.csv' with the energy data from step 0 - 0-parseEnergy.pl
#
# NOTE: working on the revised format
# NOTE: also adding relative time (for easier graphs)
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  7 Mar 2022 16:38:55 AEDT
#
#########################################################################

use List::Util qw(min);

$DEBUG = 0;

#########################################################################

# Format: two header rows, of interest is the second header row
# Columns: 'timestamp' is the first column, followed by the nodes, with
#          'Total_Energy' the last column.
#
# NOTE: it would be easier if 'Total_Energy' was the second column, but so
#       be it. The "bigger" issue is that the energy data of 12 nodes are
#       exported even if we did not run the experiment on 12 nods! Hence
#       more correction required...

# CONSTANTS - indices for the various column numbers
# NOTE: updated based on new 'starting time'...
$TIMESTAMP =  0;

# Indices for nodes...
$NODE_1    =  1;
# 'NODE_2 = NODE_1 + 1', 'NODE_3 = NODE_2 + 1'

# CONSTANTS - maximum number of nodes supported
$MAX_NODES = 12;

# CONSTANTS - for header row in output
$TIMESTAMP_HEAD    = "Timestamp";
$ENERGY_TOTAL_HEAD = "Total_energy";
$RELATIVE_TIME     = "Time";

# CONSTANT - delimeter in the ".csv" file
$DEL       = ",";

#########################################################################

# Forward declaration so that subroutines can access this...
my @MY_NODE_IPs;

#########################################################################

# Subroutine to 'impute' a value from a set of neighbouring values
# For now, let's take an average
sub impute() {
    my (@values) = @_;
    my $size = @values;
    my $count = 0;
    for $val (@values) {
	$count += $val;
    }
    return ($count / (1.0 * $size));
}

# Subroutine to 'merge' a list with a given delimiter into a single value
sub mergeDelList() {
    my ($del, @values) = @_;
    my $merged = "";
    for $val (@values) {
	$merged .= $val . $del;
    }

    # Remove the final delimiter
    chop $merged;

    return $merged;
}

#########################################################################

# Step 0 - parse command-line arguments
if (@ARGV < 2) {
    die "Insufficent number of arguments provided... \n";
}

my ($max_nodes, $energy_data) = @ARGV;

if (($max_nodes < 1) || ($max_nodes > $MAX_NODES)) {
    die "Number of nodes specified outside valid range [1-$MAX_NODE] \n";
}

#########################################################################

# Step 1 - Read the input in 'one go' and store in '@ROWS'
# NOTE: we could probably do this 'in one go' but let's do it the easy way
my $headerrow1 = "";
my $headerrow2 = "";
my $line = 0;
my $header_count = 0;
my $number_of_nodes;
@ROWS;

open (EDFH, '<', $energy_data) or die $!;
while(<EDFH>) {

    # Remove trailing newline character(s)
    chomp($_);
    $_ =~ s/\r|\n//g;

    # Process the header lines...
    if ($header_count == 0) {
	$headerrow1 = $_;
	$header_count++;
	
    } elsif ($header_count == 1) {
	$headerrow2 = $_;
	$header_count++;
	($timestamp, @REST) = split ($DEL, $_);

	# Let's fill the '@MYNODES' array - the final element is the total
	# NOTE: use at most the first 'max_nodes' nodes
	$number_of_nodes = min ($max_nodes, (@REST - 1));
	for (my $index = 0; $index < $number_of_nodes; $index++) {

	    # Some "IP" addresses contain other information, so strip it out
	    $value = @REST[$index];
	    $value =~ m/(([0-9]{1,3}\.){3}[0-9]{1,3})/;
	    
	    $MY_NODE_IPs[$index] = $1;
	}

    # Store the remaining lines - trimmed to the number of nodes
    } else {

	# NOTE: use at most the first 'max_nodes' nodes and hence need may
	#       need to recompute the total.
	($timestamp, @REST) = split ($DEL, $_);
	my $row_value = $timestamp;
	my $new_total = 0;
	for (my $index = 0; $index < $number_of_nodes; $index++) {
	    $row_value .= $DEL . @REST[$index];
	    $new_total += @REST[$index];
	}
	$row_value .= $DEL . $new_total;
	
	$ROWS[$line] = $row_value;
	$line++;
    }
}
close(EDFH);

# --------------------------------------------------------------------- #

# Step 2 - fix missing and/or double time stamps
my $previous = 0;
my %DATA;
my @MYNODES;
for ($index = 0; $index < @ROWS; $index++) {

    # Split the line up into its fields with total energy the last field
    my ($timestamp, @REST) = split ($DEL, $ROWS[$index]);
    my $total = $REST[(@REST - 1)];
    for (my $i = 0; $i < (@REST - 1); $i++) {
	$MYNODES[$i] = @REST[$i];
    }

    # print " --> processing: " . $timestamp . " (" . $previous . ")\n";

    # First line - record the timestamp.
    if ($index == 0) {
	$DATA{$timestamp} = $ROWS[$index];
	$previous = $timestamp;

    # Process all other lines
    } else {

	# Case 1 - current timestamp is a direct continuation of the previous
	if ($timestamp == ($previous + 1)) {
	    $DATA{$timestamp} = $ROWS[$index];
	    $previous = $timestamp;

	# Case 2 - we have a one second gap between 'timestamp' and 'previous'
	} elsif ($timestamp == ($previous + 2)) {

	    # Extract the relevant information for the next row
	    my ($ts2, @REST) = split($DEL, $ROWS[$index+1]);

	    # Case 2a - we have two entries for 'timestamp'
	    #           -> shift the first double entries up...
	    if ($timestamp == $ts2) {

		# Need to fix the timestamp in '$index' !!!
		my (@new_values) = split($DEL, $ROWS[$index]);
		$new_values[$TIMESTAMP] = $timestamp - 1;
		
		$DATA{$timestamp-1} = &mergeDelList($DEL, @new_values);
		$DATA{$timestamp} = $ROWS[$index+1];
		$index++;     # no need to look at the next line any more
		$previous = $timestamp;

		# print " +++> fixing gap/double situation: $timestamp\n";
		# print "$DATA{$timestamp-1}\n";
		# print "$DATA{$timestamp}\n";

	    # Case 2b - no double entry to follow we could compensate with
	    #         -> we need to impute the missing values
	    } else {

		# Need to go one row BACK and not forwards!
		my ($ts2, @REST) = split($DEL, $ROWS[$index-1]);
		my $total2 = $REST[(@REST - 1)];
		my @MYNODES2;
		for ($i2 = 0; $i2 < (@REST - 1); $i2++) {
		    $MYNODES2[$i2] = @REST[$i2];
		}

		# Impute the missing data points - could be done better...
		my $ts_new = ($previous + 1);
		my $total_new = &impute ($total, $total2);
		
		my $new_entry = $ts_new;
		for ($node = 0; $node < @MYNODES2; $node++) {
		    my $node_new = &impute (@MYNODES[$node], @MYNODES2[$node]);
		    $new_entry .= $DEL . $node_new;
		}
		$new_entry .= $DEL . $total_new;

		# Add the newly created data points (plus the existing one)
		$DATA{$ts_new} = $new_entry;
		$DATA{$timestamp} = $ROWS[$index];
		$previous = $timestamp;

		# print " +++> imputing: $ts_new\n";

	    }

	# Case 3 - we have a double entry not yet dealt with
	#          -> skip the second entry    
	} elsif ($timestamp == $previous) {

	    # print " +++> double entry: $timestamp\n";
	    # SKIP
	}
    }
}

# --------------------------------------------------------------------- #

# Step 3 - Print the corrected data - including the new header row
# NOTE: add an empty second column to stay consistent with previous data
my $headerrow = $TIMESTAMP_HEAD . $DEL . $RELATIVE_TIME;
$headerrow .= $DEL . $ENERGY_TOTAL_HEAD;
for $node_ip (@MY_NODE_IPs) {
    $headerrow .= $DEL . $node_ip;
}
print $headerrow . "\n";

$previous = 0;
$rel_time = 0;
for $timestamp (sort keys %DATA) {

    # Basic sanity check...
    if (($timestamp <=> ($previous + 1)) && ($previous <=> 0)) {
	print " --> Error: inconsistent data after corrections...";
	print " $timestamp -- $previous \n";
    }
    
    # Printing - 'total_energy' to become the second column
    my ($ts, @REST) = split ($DEL, $DATA{$timestamp});
    my $data = $ts . $DEL . $rel_time . $DEL . $REST[(@REST - 1)];
    for (my $index; $index < (@REST - 1); $index++) {
	$data .= $DEL . $REST[$index];
    }
    print $data . "\n";

    # Update '$previous' and '$rel_time'
    $previous = $timestamp;
    $rel_time++;
}

# EOS

#########################################################################
