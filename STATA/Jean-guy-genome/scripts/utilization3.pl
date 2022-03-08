#!/usr/bin/env perl
#
# Simple Perl-script to summarize the node utilizations across an experiment
#
# Argument:
#  - a folder that contains subfolders with the experimental data
#
# NOTE: a few "improvements"...
# NOTE: added mProject vs non-mProject comparison
# 
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Sun  4 Apr 2021 17:27:05 AEST
#
#########################################################################

use File::Slurp qw(read_dir);

$DEBUG = 0;

#########################################################################

# CONSTANTS - the relevant columns in the 'details' spreadsheet
$TIME_STAMP  =  0;
$TIME        =  1;
$NODE_IP     =  2;
$NODE_ID     =  3;
$WAITING     =  4;

$MPROJECT    = 11;
$NODE_ACTIVE = 14;
$UTILIZATION = 16;

# CONSTANT - the 'suffix' for a 'details' spreadsheet
$DETAILS     = "-detail.csv";

# CONSTANTS - values for the 'all' node. We ignore everything else
$ALL_NODE_IP = "All";
$ALL_NODE_ID = -1;

# CONSTANTS - for output
@CATEGORIES = (1, 2, 3, 4, 5, 6);
@CATEGORIES = (1, 2, 3, 4);
$NO_NODES   = "NoNodes";
$MEAN       = "Average";
$MEDIAN     = "Median";

# CONSTANTS - summary types
$TYPE         = "SummaryType";
$OVERALL      = "All";
$MPROJECT_ON  = "mProjectRunning";
$MPROJECT_OFF = "mProjectDone";
@ORDER        = ($OVERALL, $MPROJECT_ON, $MPROJECT_OFF);

# Delimeters etc.
$DEL   = ",";
$ATTIC = "Attic";

#########################################################################

# Subroutine to check whether a given value represents an integer
# Source: https://stackoverflow.com/questions/3803850/how-do-i-decide-if-a-variable-is-numeric-in-perl
sub is_int() {
    
    my $str = $_[0];
    my $result = 0;

    # Trim whitespace both sides
    $str =~ s/^\s+|\s+$//g;          

    # Flatten to string and match dash or plus and one or more digits
    if ($str =~ /^(\-|\+)?\d+?$/) {
        $result = 1;
    } else{
        $result = 0;
    }

    return $result
}

# Subroutine to calculate the average (mean) and median of an array of values
sub calcMeanMedian() {
    
    my @values = @_;

    # Average (mean)
    my $sum = 0;
    for $val (@values) {
	$sum += $val;
    }
    my $average = ($sum / (1.0 * @values));

    # Median - we need to sort...
    my @sorted = sort { $a <=> $b } @values;
    my $median;
    if ((@values % 2) == 1) {
	$median = $sorted[int(@values/2)];
    } else {
	$median = ($sorted[@values/2] + $sorted[(@values/2)-1]) / 2.0
    }

    return ($average, $median);
}

# Subroutine to find the 'details' spreadsheet in a directory
# NOTE: we match for a '-details.csv' suffix. If there were multiple, we
#       take the first one... if we find none, we return an empty string
sub getDetailsFileName() {

    my $folder = $_[0];
    my $filename = "";

    opendir DIR,$folder;
    my @dir = readdir(DIR);
    close DIR;

    foreach (@dir) {

	# Do we have a file?
	if (-f $folder . "/" . $_ ) {

	    # Get the name of this file
	    my $filename = $_;

	    # Does 'file_name' match the pattern given in '$DETAILS'?
	    if ($filename =~ m/(.*)(\-detail\.csv)/) {

		# We stop the iteration...
		return $filename;
	    }
	}
    }

    return $filename;
}

#########################################################################

# Subroutine to 'categorize' a utilization value "u" into one of the
# non-overlapping ranges. For now, we have the following 'buckets':
#
# - 1   -->  u <= 0.20
# - 2   --> 0.20 < u <= 0.50
# - 3   --> 0.50 < u <= 0.90
# - 4   --> 0.90 < u
#
# These 'buckets' can be changed down the track (if required)
sub getCategoryValue() {

    my $value = $_[0];
    my $bucket = 1;       # default bucket

    if (($value > 0.20) && ($value <= 0.50)) {
	$bucket = 2;
    } elsif (($value > 0.50) && ($value <= 0.90)) {
	$bucket = 3;
    } elsif ($value > 0.90) {
	$bucket = 4;
    }

    return $bucket;
}

# --------------------------------------------------------------------- #

# Subroutine to 'categorize' a utilization value "u" into one of the
# non-overlapping ranges. For now, we have the following 'buckets':
#
# - 1   --> u < 0.20
# - 2   --> 0.20 <= u < 0.40
# - 3   --> 0.40 <= u < 0.60
# - 4   --> 0.60 <= u < 0.80
# - 5   --> 0.80 <= u < 1.00
# - 6   --> u = 1.00
#
sub getCategoryValueFine() {

    my $value = $_[0];
    my $bucket = 1;       # default bucket

    if ((0.20 <= $value) && ($value < 0.40)) {
	$bucket = 2;
    } elsif ((0.40 <= $value) && ($value < 0.60)) {
	$bucket = 3;
    } elsif ((0.60 <= $value) && ($value < 0.80)) {
	$bucket = 4;
    } elsif ((0.80 <= $value) && ($value < 1.00)) {
	$bucket = 5;
    } elsif ($value == 1.00) {
	$bucket = 6;
    }

    return $bucket;
}

# --------------------------------------------------------------------- #

# Subroutine to convert a list of values into the relevant categories
# NOTE: we return absolute counts to facilitate normalization later on.
sub createCategories() {

    my @values = @_;
    my %categories;

    for $val (@values) {

	# Get the category for the current value
	my $category = &getCategoryValue($val);

	# Update the relevant category count
	if ($categories{$category}) {
	    $categories{$category}++;
	} else {
	    $categories{$category} = 1;
	}
    }

    return %categories;
}

#########################################################################

# Subroutine to process a details file, get the relevant utilization values,
# and summarize into the relevant categories
sub processDetailsFile() {

    my $filename = $_[0];

    my @VALUES;               # all utilization values
    my @MPROJECT_ACTIVE;      # only when there are 'mProject' executing
    my @MPROJECT_DONE;        # only when no 'mProject' executing

    my $index        = 0;
    my $index_active = 0;
    my $index_done   = 0;

    open(FH, '<', $filename) or die $!;
    while(<FH>) {

	# Remove any end-of-line characters...
	chomp($_);
	$_ =~ s/\r|\n//g;

	# Get the value for columns 'NODE_IP' and 'NODE_ID'
	my @cells = split ($DEL, $_);

	my $node_ip     = $cells[$NODE_IP];
	my $node_id     = $cells[$NODE_ID];
	my $mProject    = $cells[$MPROJECT];
	my $waiting     = $cells[$WAITING];	
	my $node_active = $cells[$NODE_ACTIVE];

	# Ignore this row if 'node_ip' or 'node_id' do not match the flag
	# for the 'all' node
	if (($node_ip eq $ALL_NODE_IP) || ($node_id == $ALL_NODE_ID)) {

	    # Do we either have jobs waiting or jobs executing?
	    # If not, skip this row
	    if (($waiting > 0) || ($node_active > 0)) {

		# print " --> $waiting, $node_active \n";
	    
		# Get the utilization value for this row (if present)
		if ($cells[$UTILIZATION]) {
		    $VALUES[$index] = $cells[$UTILIZATION];
		} else {
		    $VALUES[$index] = 0;
		}
		$index++;

		# Do we have any 'mProject' running? If so, record utilization
		# in 'MPROJECT_ACTIVE', otherwise in 'MPROJECT_DONE'
		if ($mProject > 0) {
		    $MPROJECT_ACTIVE[$index_active] = $cells[$UTILIZATION];
		    $index_active++;
		} else {
		    $MPROJECT_DONE[$index_done] = $cells[$UTILIZATION];
		    $index_done++;
		}
	    }
	}
    }
    close(FH);

    # We can now recode the extracted values into categories, sum them up,
    # and convert to percentages
    my %ALL_VALUES    = &createCategories (@VALUES);
    my %WITH_MPROJECT = &createCategories (@MPROJECT_ACTIVE);
    my %NO_MPROJECT   = &createCategories (@MPROJECT_DONE);

    my %CATEGORIES;
    
    # Convert counts across the board into percentages
    for $category (keys %ALL_VALUES) {
	$CATEGORIES{$OVERALL}{$category} = ($ALL_VALUES{$category} / (1.0 * @VALUES));
    }

    # Get average and median
    my ($mean, $median) = &calcMeanMedian(@VALUES);
    $CATEGORIES{$OVERALL}{$MEAN}   = $mean;
    $CATEGORIES{$OVERALL}{$MEDIAN} = $median;

    # Only consider utilization values when at least one 'mProject' is running
    for $category (keys %WITH_MPROJECT) {
	$CATEGORIES{$MPROJECT_ON}{$category} = ($WITH_MPROJECT{$category} / (1.0 * @VALUES));
    }

    # Get average and median
    ($mean, $median) = &calcMeanMedian(@MPROJECT_ACTIVE);
    $CATEGORIES{$MPROJECT_ON}{$MEAN}   = $mean;
    $CATEGORIES{$MPROJECT_ON}{$MEDIAN} = $median;
    
    # Only consider utilization values when no 'mProject' job is running
    for $category (keys %NO_MPROJECT) {
	$CATEGORIES{$MPROJECT_OFF}{$category} = ($NO_MPROJECT{$category} / (1.0 * @VALUES));
    }
    
    # Get average and median
    ($mean, $median) = &calcMeanMedian(@MPROJECT_DONE);
    $CATEGORIES{$MPROJECT_OFF}{$MEAN}   = $mean;
    $CATEGORIES{$MPROJECT_OFF}{$MEDIAN} = $median;
    
    return %CATEGORIES;
}
			 
#########################################################################

# Step 0 - parse the command-line arguments. We need one directory
if (@ARGV < 1) {
    die "Insufficient input files given...";
}

my $ROOT_DIR = $ARGV[0];

# --------------------------------------------------------------------- #

# Step 1 - get the names of all sub-folders. Their values must be an
#          integer value.
my @DIRS;
my $count = 0;
my $root = $ROOT_DIR;
for my $dir (grep { -d "$root/$_" } read_dir($root)) {
    $DIRS[$count] = $dir;
    $count++;
}

# DEBUGGING
if ($DEBUG == 1) {
    for my $dir (@DIRS) {
	if (&is_int($dir)) {
	    print $dir . "\n";
	} else {
	    print "$dir is not a numeric value...\n";
	}
    }
    print "\n";
}

# --------------------------------------------------------------------- #

# Step 2 - iterate over all 'integer' directories, access the 'details'
#          spreadsheet, and extract the utilization data (in percentages)
%RESULTS;
for my $dir (@DIRS) {

    # Skip the 'Attic' directory
    if ($dir eq $ATTIC) {
	next;
    }
    
    # Do we have a directory with an 'integer' value? If so, proceed...
    if (&is_int($dir)) {

	# Find the name of the 'details' spreadsheet in directory
	my $sub_dir = $ROOT_DIR . "/" . $dir;
	my $details_file = &getDetailsFileName($sub_dir);

	# Have we found such a file? If so, proceed. If not, skip
	if ($details_file) {

	    my $file = $sub_dir . "/" . $details_file;
	    my %CATEGORIES =  &processDetailsFile($file);

	    # Copy the category percentages as well as the average and median
	    # across for further processing
	    for $type (@ORDER) {
		for $cat (@CATEGORIES, $MEAN, $MEDIAN) {
		    
		    $RESULTS{$dir}{$type}{$cat} = $CATEGORIES{$type}{$cat};
		}
	    }
	}
	
    } else {
	print "$dir is not a numeric value and cannot be processed...\n";
    }
}

# --------------------------------------------------------------------- #

# Step 3 - print the summarized information
my $header = $NO_NODES;
$header .= $DEL . $TYPE;
$header .= $DEL . $MEAN . $DEL . $MEDIAN;
for $cat (@CATEGORIES) {
    $header .= $DEL . $cat;
}
print $header . "\n";

# Print the summarized categories
for $nodes (sort { $a <=> $b } keys %RESULTS) {

    for $type (@ORDER) {
	print $nodes;
	print $DEL . $type;
	print $DEL . $RESULTS{$nodes}{$type}{$MEAN};
	print $DEL . $RESULTS{$nodes}{$type}{$MEDIAN};
	for $cat (@CATEGORIES) {
	    printf ("$DEL %.10f", $RESULTS{$nodes}{$type}{$cat});
	}
	print "\n";
    }
}

# EOS

#########################################################################
