#!/use/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Net::SNMP;
no warnings 'redefine';

# Connection information
our $host = $ARGV[0];
our $community = $ARGV[1];
our $port = $ARGV[2];

# OID List
our $vlanList_OID = '.1.3.6.1.4.1.9.9.46.1.3.1.1.2';
our $macBridge_OID = '.1.3.6.1.2.1.17.4.3.1.1';
our $bridgeList_OID = '1.3.6.1.2.1.17.4.3.1.2';
our $ifIndexList_OID = '.1.3.6.1.2.1.17.1.4.1.2';
our $ifNameList_OID = '.1.3.6.1.2.1.31.1.1.1.1';
our $ifAdminStatus_OID = '.1.3.6.1.2.1.2.2.1.7';
our $ifOperStatus_OID = '.1.3.6.1.2.1.2.2.1.8';

our %macData;
our %bridgeNumData;

# Establish session
my ($session,$error) = Net::SNMP->session (
     -hostname => $host,
     -community => $community,
	-timeout => 1,
	-retries => 1,
);

# Get the index number of the port
our $portIndex = &get_index_number();
our $portID = &get_indexes($session);
our %portBridgeNums;
our %macs;

print "Data for port $port on $host:\n";

my $adminState = &get_admin_state();
print "Administrative state: $adminState\n";

my $portState = &get_port_state();
print "Activity state: $portState\n";

# Get a list of all VLANs
my $vlanList = $session->get_table(-baseoid => $vlanList_OID);

while (my($vlanID,$opCode) = each(%$vlanList)) {
	$vlanID =~ s/$vlanList_OID\.1\.//;
	my ($vlanSession,$vlanError) = Net::SNMP->session (
		-hostname => $host,
		-community => "$community\@$vlanID",
	);
	$portID = &get_indexes($vlanSession);
	my $bridgeReturn = &get_bridge_nums($vlanSession);

	&get_macs($vlanSession);
	&get_bridge_nums($vlanSession);
	$vlanSession->close();
}

while (my ($mac,$bridgeNum) = each(%macData)) {
	if($bridgeNumData{$bridgeNum}) {
		print &format_mac($mac)."\n";
	}
}

sub get_macs() {
	my $vlanSession = $_[0];
	#my $bridgeNum = $_[1];

	my $macBridgeList = $vlanSession->get_table(-baseoid => $macBridge_OID);
	while (my($bridgeID,$mac) = each(%$macBridgeList)) {
		$bridgeID =~ s/$macBridge_OID\.//;
		$mac =~ s/^0x//;
		if($mac =~ m/[0-9a-fA-F]{12}/) {
			$macData{$mac} = $bridgeID;
		}
	}
}

sub get_bridge_nums() {
	my $vlanSession = $_[0];

	my $bridgeList = $vlanSession->get_table(-baseoid => $bridgeList_OID);
	while (my($bridgeID,$bridgeNum) = each(%$bridgeList)) {
		$bridgeID =~ s/$bridgeList_OID\.//;
		if($bridgeNum == $portID) {
			$bridgeNumData{$bridgeID} = $bridgeNum;
		}
	}
}

sub get_indexes() {
	my $vlanSession = $_[0];

	my $ifIndexList = $vlanSession->get_table(-baseoid => $ifIndexList_OID);
	while (my($ifID,$ifIndex) = each(%$ifIndexList)) {
		$ifID =~ s/$ifIndexList_OID\.//;
		#$ifIndexData{$ifID} = $ifNameData{$ifIndex};
		if($ifIndex == $portIndex) {
			return $ifID;	
		}
	}
}

sub get_index_number() {
	my $ifNameList = $session->get_table(-baseoid => $ifNameList_OID);
	while (my($ifIndex,$ifName) = each(%$ifNameList)) {
		$ifIndex =~ s/$ifNameList_OID\.//;
		if($ifIndex =~ m/\d{5}/) {
			if($ifName eq $port) {
				return $ifIndex;
			}
		}
	}
}

sub format_mac() {
	my $mac = $_[0];
	#$mac =~ s/(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/$1:$2:$3:$4:$5:$6/;
	$mac =~ s/(.{2})/$1:/gg;
	$mac =~ s/\:$//;
	return $mac;
}

sub get_admin_state() {
	my $portIndexStatus = $session->get_table(-baseoid => $ifAdminStatus_OID);
	while (my($ifIndex,$portState) = each(%$portIndexStatus)) {
		$ifIndex =~ s/$ifAdminStatus_OID\.//;
		if($ifIndex == $portIndex) {
			return $portState;
		}
	}
}

sub get_port_state() {
	my $portIndexStatus = $session->get_table(-baseoid => $ifOperStatus_OID);
	while (my($ifIndex,$portState) = each(%$portIndexStatus)) {
		$ifIndex =~ s/$ifOperStatus_OID\.//;
		if($ifIndex == $portIndex) {
			return $portState;
		}
	}
}

# Close initial session
$session->close();
