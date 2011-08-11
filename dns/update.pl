#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use Net::DNS;

# Key info
my $keyname = 'KEYNAME';
my $key = 'KEY'; 

# Update packet
my $update = Net::DNS::Update->new('grantcohoe.com');

# No A records can exist
$update->push(pre => nxrrset('foo.grantcohoe.com. A'));
#$update->push(pre => yxrrset('foo.grantcohoe.com. A'));

# Add record
$update->push(update => rr_add('foo.grantcohoe.com. 3600 A 192.168.0.1'));

# Sign it
$update->sign_tsig($keyname, $key);

# Send the record
my $res = Net::DNS::Resolver->new;
$res->nameservers('129.21.50.103');

# Reply
my $reply = $res->send($update);

# Check if it worked or not
if($reply) {
	if($reply->header->rcode eq 'NOERROR') {
		print "Success!\n";
	}
	else {
		print &interpret_error($reply->header->rcode);
	}
}
else {
	print &interpret_error($res->errorstring);
}


sub interpret_error() {
	my $error = shift(@_);

	given ($error) {
		when (/NXRRSET/) {
			return "Error $error: Name does not exist\n";
		}
		when (/YXRRSET/) {
			return "Error $error: Name exists\n";
		}
		default {
			return "$error unrecognized\n";
		}
	}
}
