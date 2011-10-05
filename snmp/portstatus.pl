#!/use/bin/perl

use strict;
use warnings;
use Net::SNMP;
no warnings 'redefine';

# Connection information
our $host = $ARGV[0];
our $community = $ARGV[1];

# OID List
our $ifName_OID = '.1.3.6.1.2.1.31.1.1.1.1';
our $ifOperStatus_OID = '.1.3.6.1.2.1.2.2.1.8';

my %ifIndexData;
my %ifNameData;

# Establish session
my ($session,$error) = Net::SNMP->session (
     -hostname => $host,
     -community => $community,
);

# Get a listing of all port indexes and their current state
my $portIndexStatus = $session->get_table(-baseoid => $ifOperStatus_OID);
while (my($ifIndex,$portState) = each(%$portIndexStatus)) {
	$ifIndex =~ s/$ifOperStatus_OID\.//;
	if($ifIndex =~ m/\d{5}/) {
		$ifIndexData{$ifIndex} = $portState;
	}
}

# Get a list of all port names?
my $portNames = $session->get_table(-baseoid => $ifName_OID);
while (my($ifIndex,$ifName) = each(%$portNames)) {
	$ifIndex =~ s/$ifName_OID\.//;
	if($ifIndex =~ m/\d{5}/) {
		$ifNameData{$ifIndex} = $ifName;
	}
}

# Map the data;
while (my ($ifIndex,$ifName) = each(%ifNameData)) {
	print "$ifName - $ifIndexData{$ifIndex}\n";
}

# Close session
$session->close();
