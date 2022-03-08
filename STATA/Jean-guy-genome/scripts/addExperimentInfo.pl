#!/usr/bin/env perl
#
# Simple Perl-script to add information about a specific experiment to an
# already computed experiment.
#
# Argument:
#  - a folder that contains subfolders with the experimental data
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  5 Apr 2021 10:35:37 AEST
#
#########################################################################

use File::Slurp qw(read_dir);

$DEBUG = 0;

#########################################################################

# CONSTANT - the 'suffix' of the experimental spreadsheet
# NOTE: can be altered for other experiments
$REGEX    = "-jobs.csv";

# CONSTANTS - additiona columns at the END - not to distort other column info
$NO_NODES = "NoNodes";
$DEGREES  = "Degrees";

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

# Subroutine to find the experimental spreadsheet in a directory
# NOTE: we match for the 'REGEX' given above. If there were multiple matches,
#       we take the first one... if we find none, we return an empty string
sub getRegexFileName() {

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
	    if ($filename =~ m/(.*)($REGEX)(.*)/) {

		# We stop the iteration...
		return $filename;
	    }
	}
    }

    return $filename;
}

# --------------------------------------------------------------------- #

# Subroutine to print the contents of 'file_name' with two additional columns
# at the end for (i) degrees and (ii) number of nodes
# NOTE: only print the header for the FIRST file processed and omit otherwise.
my $firstHeader = 1;

sub printAmendedFile() {

    my ($degrees, $no_nodes, $filename) = @_;
    my $header = 1;

    open(FH, '<', $filename) or die $!;
    while(<FH>) {

	# Remove any end-of-line characters...
	chomp($_);
	$_ =~ s/\r|\n//g;

	# Are we processing the first header row overall? If so, print it
	if (($firstHeader == 1) && ($header == 1)) {

	    # Print the amended header row
	    print $_ . $DEL . $DEGREES . $DEL . $NO_NODES . "\n";	    

	    $firstHeader = 0;
	    $header = 0;
 
	# Are we processing any subsequent headers? If so, ignore header row
	} elsif (($firstHeader == 0) && ($header == 1)) {

	    $header = 0;

	# Process any of the non-header rows
	} else {

	    # Print the amended row
	    print $_ . $DEL . $degrees . $DEL . $no_nodes . "\n";
	}

    }
    close(FH);
}

#########################################################################

# Step 0 - parse the command-line arguments. We need one directory
if (@ARGV < 1) {
    die "Insufficient input files given...";
}

my $ROOT_DIR = $ARGV[0];

# --------------------------------------------------------------------- #

# Step 1 - get the names of all sub-folders. Their values must be an
#          integer value for them to be further considered. The integer
#          value represents the number of nodes.
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

# Step 2 - iterate over all 'integer' directories, access the relevant
#          spreadsheet, add the relevant node and degrees information,
#          and merge the amended contents.
for my $dir (sort { $a <=> $b } @DIRS) {

    # Skip the 'Attic' directory
    if ($dir eq $ATTIC) {
	next;
    }
    
    # Do we have a directory with an 'integer' value? If so, proceed...
    if (&is_int($dir)) {

	# Find the name of the 'details' spreadsheet in directory
	my $sub_dir = $ROOT_DIR . "/" . $dir;
	my $file_name = &getRegexFileName($sub_dir);

	# Have we found such a file? If so, proceed. If not, skip
	if ($file_name) {

	    # Extract degrees and number of nodes from 'file_name'?
	    if ($file_name =~ m/(.*)\-([0-9]+)n(.*)/) {

		my $degrees   = $1;
		my $no_nodes  = $2;

		my $full_name = $sub_dir . "/" . $file_name;

		# Final step - print
		&printAmendedFile ($degrees, $no_nodes, $full_name);
		
	    } else {
		print "Inconsistent naming in $file_name...\n";
	    }
	}
	
    } else {
	print "$dir is not a numeric value and cannot be processed...\n";
    }
}

# EOS

#########################################################################
