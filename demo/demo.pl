#!/usr/bin/perl

use strict;
use warnings;

sub doSomething {
	#my ($message,$value) = @_;
	my $message = $_[0];
	my $value = $_[1];
	print "Message: $message; Value $value\n";
}

&doSomething("Hi There!","Person");
