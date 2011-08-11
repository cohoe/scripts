#!/use/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Net::SNMP;
no warnings 'redefine';

# Connection information
our $host = $ARGV[0];
our $community = $ARGV[1];

# OID List
our $ifAliasList_OID = '1.3.6.1.2.1.31.1.1.1.18';
our $ifNameList_OID = '.1.3.6.1.2.1.31.1.1.1.1';

# Data
our %ifNameData;

# Establish session
my ($session,$error) = Net::SNMP->session (
     -hostname => $host,
     -community => $community,
);

# Get a list of all port names;
&get_names($session);
&get_aliases();

sub get_names() {
	my $vlanSession = $_[0];

	my $ifNameList = $vlanSession->get_table(-baseoid => $ifNameList_OID);
	while (my($ifIndex,$ifName) = each(%$ifNameList)) {
		$ifIndex =~ s/$ifNameList_OID\.//;
		if($ifIndex =~ m/\d{5}/) {
			$ifNameData{$ifIndex} = $ifName;
		}
	}
}

sub get_aliases() {
	my $ifAliasList = $session->get_table(-baseoid => $ifAliasList_OID);
	while (my($ifIndex,$ifAlias) = each(%$ifAliasList)) {
		$ifIndex =~ s/$ifAliasList_OID\.//;
		if($ifIndex =~ m/\d{5}/) {
			print "$ifNameData{$ifIndex} - $ifAlias\n";
		}
	}
}

# Close initial session
$session->close();
