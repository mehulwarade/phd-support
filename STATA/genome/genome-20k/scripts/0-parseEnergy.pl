#!/usr/bin/env perl
#
# Simple Perl-script to 'convert' the energy measurements of experiments
# into the format we need for further processing
#
# Arguments:
#  - the '.csv' with the raw energy data
#  - the mapping file that translates 'p_x' to 'node_y'
#
# Note: we have to assume that 'Node_1' has IP address '192.168.5.101',
#       'Node_2' has IP address '192.168.5.102' etc.
#
# Author: Jean-Guy Schneider <schneidr@acm.org>
# Date:   Mon  7 Mar 2022 14:24:37 AEDT
#
#########################################################################

use List::Util qw(min);

$DEBUG = 0;

#########################################################################

# Constants
$BASE_IP    = "192.168.5";
$BASE_START = 100;

# We are adding the total energy at the end (for compatibility reasons)
$TOTAL_ENERGY = "Total_Energy";

# CONSTANTS - various delimeteres
$DEL         = ",";
$SEP         = ".";

#########################################################################

# Subroutine to print debugging information (only if '$DEBUG' is not 0)
sub printDebugInfo() {
    my ($text, @REST) = @_;
    if ($DEBUG) {
	print $text;
    }
}

# Subroutine to 'calculate' the IP address for node_x
# NOTE: see comment in the header about this!
sub getIPAddress() {

    my ($id, @REST) = @_;
    my $host = $BASE_START + $id;    
    return ($BASE_IP . $SEP . $host);
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
if (@ARGV < 2) {
    die "Insufficient input files given...";
}

my $energy_data  = "";
my $mapping_data = "";
($energy_data, $mapping_data) = @ARGV;

# -------------------------------------------------------------------------- #

# Step 1 - read the raw energy data
$first = 1;
$header;
@PORTS;
@ENERGY_DATA;
$index = 0;

# Open the 'energy data' file and read its contents.
open (EDFH, '<', $energy_data) or die $!;
while(<EDFH>) {

    # Remove trailing newline character(s)
    chomp($_);
    $_ =~ s/\r|\n//g;

    # Are we processing the header line?
    if ($first) {

	# Keep track of the header
	$header = $_;

	# Split the header into its fields
	# We have: timestamp,description,p1,p2, ...
	($timestamp, $desc, @PORTS) = split($DEL, $header);
	
	# Record that we have processed the header
	$first = 0;

    # Processing any subsequent lines
    } else {

	# We store the data into an array as the 'timestamp' is not always
	# unique! We will then have to split the data afterwards...
	@ENERGY_DATA[$index] = $_;
	$index++;	
    }
}
close(EDFH);

# Basic debugging
&printDebugInfo(" --> number of ports in input: " . (@PORTS + 0) . "\n");
&printDebugInfo(" --> number of timestamps in input: " . (@ENERGY_DATA + 0) . "\n");

# -------------------------------------------------------------------------- #

# Step 2 - read the mapping data
%NODE_MAP;
$first = 1;

# Open the 'mapping data' file and read its contents.
open (MDFH, '<', $mapping_data) or die $!;
while(<MDFH>) {

    # Remove trailing newline character(s)
    chomp($_);
    $_ =~ s/\r|\n//g;

    # We simply skip the header as we do not really need it...
    if ($first) {
	$first = 0;

    # We are expecting a (node_x, p_y) pair
    } else {
	
	# Split into 'node_x' and 'port_y'
	my ($nodeID, $portID) = split ($DEL, $_);

	# Do we have information about 'portID'?
	if (&isInList ($portID, @PORTS)) {

	    # Extract the 'number' from 'node_x'
	    if ($nodeID =~ /[Nn]ode(([0-9]+))/) {

		my $id = $1;
		$NODE_MAP{$id} = $portID;
	    }
	}
    }
}
close(MDFH);

# Basic debugging
for my $n (sort { $a <=> $b } keys %NODE_MAP) {
    &printDebugInfo(" --> Node: " . $n . ", port: " . $NODE_MAP{$n} . "\n");
}

# -------------------------------------------------------------------------- #

# Step 3 -> reduce the energy data to the nodes listed in the mapping file

# Step 3a -> we need to create the new header information
my $newhead1 = $timestamp;
my $newhead2 = $timestamp;
for my $node (sort { $a <=> $b } keys %NODE_MAP) {

    # For the first header: we need the port name/number for each node
    $newhead1 .= $DEL . $NODE_MAP{$node};

    # For the second header: we need the IP address of this node.
    my $ip_address = &getIPAddress($node);
    $newhead2 .= $DEL . $ip_address;
}

# Print the two created headers
print $newhead1 . $DEL . $TOTAL_ENERGY . "\n";;
print $newhead2 . $DEL . $TOTAL_ENERGY . "\n";;

# Step 3b -> let's create a lookup table so that we can better access energy
# value based on port number and not node id
my %PORT_INDEX;
for my $node (sort { $a <=> $b } keys %NODE_MAP) {
    
    my $port = $NODE_MAP{$node};
    my $length = (@PORTS + 0);
    for ($index = 0; $index < $length; $index++) {

	# Have we found 'port' in the list of recorded porsts?
	if ($port eq @PORTS[$index]) {
	    $PORT_INDEX{$port} = $index;
	    break;
	}
    }   
}

# Debugging
for $val (sort keys %PORT_INDEX) {
    &printDebugInfo(" --> Port: " . $val . ", index: " . $PORT_INDEX{$val} . "\n");
}

# Step 3c -> now we need to iterate over 'ENERGY_DATA', extract the relevant
#            values, and add up a total.
foreach $info (@ENERGY_DATA) {

    my $total = 0;
    
    # Split 'info' into the relevant parts
    my ($ts, $desc, @ports) = split($DEL, $info);

    # Initialize a new output line
    my $newline = $ts;

    # Iterate over available node ids, get the corresponding port id and value
    for my $node (sort { $a <=> $b } keys %NODE_MAP) {

	# Get the index into '@ports' to retrived the energy value
	my $index = $PORT_INDEX{ $NODE_MAP{$node} };
	$newline .= $DEL . @ports[$index];

	# ... and add to 'total'
	$total += @ports[$index];
    }

    print $newline . $DEL . $total . "\n";
}

# EOS

#########################################################################
