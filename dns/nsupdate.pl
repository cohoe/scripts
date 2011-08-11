#!/usr/bin/perl

use strict;
use warnings;
use Net::DNS;

my $res = Net::DNS::Resolver->new;
my $query = $res->search("ns1.csh.rit.edu");

if ($query) {
	foreach my $rr ($query->answer) {
		next unless $rr->type eq "A";
		print $rr->address, "\n";
	}
}
else {
	warn "Fail: ", $res->errorstring, "\n";
}

my @mx = mx($res, "csh.rit.edu");
if(@mx) {
	foreach my $rr (@mx) {
		print $rr->exchange, " - ", $rr->preference, "\n";
	}
}
else  {
	warn "Fail: ", $res->errorstring, "\n";
}
