#!/use/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Net::SNMP;
use Socket;
no warnings 'redefine';

# Connection information
our $host = $ARGV[0];
our $community = $ARGV[1];

# OID List
our $vlanList_OID = '.1.3.6.1.4.1.9.9.46.1.3.1.1.2';
our $macBridge_OID = '.1.3.6.1.2.1.17.4.3.1.1';
our $bridgeList_OID = '1.3.6.1.2.1.17.4.3.1.2';
our $ifIndexList_OID = '.1.3.6.1.2.1.17.1.4.1.2';
our $ifNameList_OID = '.1.3.6.1.2.1.31.1.1.1.1';
our $arpTable_OID = '1.3.6.1.2.1.4.22.1.2';

our %ifNameData;
our %ifIndexData;
our %bridgeNumData;
our %arpData;
our %macPortData;
our %hostNameData;

# Establish session
my ($session,$error) = Net::SNMP->session (
     -hostname => $host,
     -community => $community,
);

# Get a list of all VLANs
my $vlanList = $session->get_table(-baseoid => $vlanList_OID);

while (my($vlanID,$opCode) = each(%$vlanList)) {
	$vlanID =~ s/$vlanList_OID\.1\.//;
	my ($vlanSession,$vlanError) = Net::SNMP->session (
		-hostname => $host,
		-community => "$community\@$vlanID",
	);
	&get_names($vlanSession);
	&get_indexes($vlanSession);
	&get_bridge_nums($vlanSession);
	&get_macs($vlanSession);
	$vlanSession->close();
}

&get_ip($session);

sub get_macs() {
	my $vlanSession = $_[0];

	my $macBridgeList = $vlanSession->get_table(-baseoid => $macBridge_OID);
	while (my($bridgeID,$mac) = each(%$macBridgeList)) {
		$bridgeID =~ s/$macBridge_OID\.//;
		$mac =~ s/^0x//;
		if($mac =~ m/[0-9a-fA-F]{12}/) {
			#$mac = &format_mac($mac);
			#print "$bridgeNumData{$bridgeID} - $mac\n";
			$macPortData{$mac} = $bridgeNumData{$bridgeID};
		}
	}
}

sub get_bridge_nums() {
	my $vlanSession = $_[0];

	my $bridgeList = $vlanSession->get_table(-baseoid => $bridgeList_OID);
	while (my($bridgeID,$bridgeNum) = each(%$bridgeList)) {
		$bridgeID =~ s/$bridgeList_OID\.//;
		$bridgeNumData{$bridgeID} = $ifIndexData{$bridgeNum};
	}
}

sub get_indexes() {
	my $vlanSession = $_[0];

	my $ifIndexList = $vlanSession->get_table(-baseoid => $ifIndexList_OID);
	while (my($ifID,$ifIndex) = each(%$ifIndexList)) {
		$ifID =~ s/$ifIndexList_OID\.//;
		$ifIndexData{$ifID} = $ifNameData{$ifIndex};
	}
}

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

sub get_ip() {
	my $vlanSession = $_[0];

	my $arpList = $vlanSession->get_table(-baseoid => $arpTable_OID);
	while (my($ipAddr,$mac) = each(%$arpList)) {
		$ipAddr =~ s/$arpTable_OID\.\d{2}\.//;
		$mac =~ s/^0x//;
		if($mac =~ m/[0-9a-fA-F]{12}/) {
			my $hostName = gethostbyaddr(inet_aton($ipAddr),AF_INET);
			if($macPortData{$mac}) {
				if(!$hostName) { $hostName = ""; }
				#print "$hostName - $macPortData{$mac}\n";
				#$hostNameData{$macPortData{$mac}} = $hostName;
				#$hostNameData{$hostName} = $macPortData{$mac};
				print "$macPortData{$mac} - $ipAddr - $hostName\n";
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

# Close initial session
$session->close();
