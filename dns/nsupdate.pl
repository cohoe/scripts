#!/usr/bin/perl

use strict;
use warnings;
use WWW::Curl::Easy;
use Net::DNS;
use Socket;
use YAML::XS qw(LoadFile);

my $config = LoadFile 'nsupdate.yml';
our $dns_keyname = $config->{dns_keyname};
our $dns_key = $config->{dns_key};
our $dns_zone = $config->{dns_zone};
our $hostname = $config->{hostname};
our $ip_address = &get_ip_address();
our $ns_ip_address = &get_ns_ip;
&update_dns;

# Get the public facing IP address of the host
sub get_ip_address {
	# Establish the cURL object
	my $curl = WWW::Curl::Easy->new;
	
	# Make some data and set the cURL options
	$curl->setopt(CURLOPT_URL, 'http://ipv4.icanhazip.com');
	my $ip_address;
	$curl->setopt(CURLOPT_WRITEDATA,\$ip_address);
	
	# Perform the request
	my $retcode = $curl->perform;
	
	# Check for error
	if($retcode != 0) {
		die "cURL error $retcode: ".$curl->strerror($retcode)." - ".$curl->errbuf."\n";
	}
	
	# Get the address
	chomp($ip_address);
	return $ip_address;
}

# Execute the update to the NS
sub update_dns {
	# Update packet
	my $update = Net::DNS::Update->new($dns_zone);

	# Add record
	$update->push(update => rr_add("$hostname.$dns_zone. 3600 A $ip_address"));

	# Sign it
	$update->sign_tsig($dns_keyname, $dns_key);

	# Send the record
	my $res = Net::DNS::Resolver->new;
	$res->nameservers($ns_ip_address);

	# Reply
	my $reply = $res->send($update);

	# Check if it worked or not
	if($reply) {
		if($reply->header->rcode eq 'NOERROR') {
			print "Success!\n";
		}
		else {
			die "Update query failed: ",$reply->header->rcode,"\n";
		}
	}
	else {
		die "Update query failed: ",$res->errorstring,"\n";
	}
}

sub get_ns_ip {
	my $res   = Net::DNS::Resolver->new;
  	my $query = $res->query($dns_zone, "SOA");
  
	if ($query) {
		foreach my $rr ($query->answer) {
			my $ipaddr = gethostbyname($rr->mname);
			return inet_ntoa($ipaddr);
		}  
	} 
	else {
		die "SOA query failed: ",$res->errorstring,"\n";
	}
}
